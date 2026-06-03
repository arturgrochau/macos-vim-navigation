import Foundation
import IOKit
import KeyDeckCore

/// Fill these after creating the Gumroad product. `productID` is the product's ID
/// (Gumroad: Product → Advanced → "product_id"); `buyURL` is its public page.
enum LicenseConfig {
    static let productID = "YOUR_GUMROAD_PRODUCT_ID"
    static let buyURL = URL(string: "https://gumroad.com/l/keydeck")!
    static let maxActivations = 3
    static let reverifyAfterDays = 7.0
}

enum LicenseError: Error, LocalizedError {
    case invalid, activationLimit, network, notConfigured
    var errorDescription: String? {
        switch self {
        case .invalid: return "That license key wasn't recognized."
        case .activationLimit: return "This license has reached its activation limit."
        case .network: return "Couldn't reach the license server. Check your connection."
        case .notConfigured: return "Licensing isn't configured yet (set LicenseConfig.productID)."
        }
    }
}

/// Owns the on-disk LicenseState, the Gumroad verification call, and machine binding.
@MainActor
final class LicenseManager: ObservableObject {
    @Published private(set) var state: LicenseState

    private static var fileURL: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("KeyDeck", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("license.json")
    }

    init(now: Date = Date()) {
        if let data = try? Data(contentsOf: Self.fileURL),
           let s = try? Self.decoder.decode(LicenseState.self, from: data) {
            state = s
        } else {
            state = .startingTrial(now: now)
            persist()
        }
    }

    var isApplyAllowed: Bool { state.isApplyAllowed(now: Date()) }
    func statusText() -> String { state.statusText(now: Date()) }

    /// Verify a key with Gumroad, bind it to this machine, and cache the result.
    func activate(key: String) async -> Result<Void, LicenseError> {
        guard LicenseConfig.productID != "YOUR_GUMROAD_PRODUCT_ID" else { return .failure(.notConfigured) }
        var req = URLRequest(url: URL(string: "https://api.gumroad.com/v2/licenses/verify")!)
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        req.httpBody = "product_id=\(LicenseConfig.productID)&license_key=\(trimmed)&increment_uses_count=true"
            .data(using: .utf8)
        do {
            let (data, _) = try await URLSession.shared.data(for: req)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  json["success"] as? Bool == true else { return .failure(.invalid) }
            let uses = json["uses"] as? Int
            if let uses, uses > LicenseConfig.maxActivations { return .failure(.activationLimit) }
            let purchase = json["purchase"] as? [String: Any]
            state.licenseKey = trimmed
            state.email = purchase?["email"] as? String
            state.verifiedAt = Date()
            state.machineID = Self.machineID()
            state.uses = uses
            persist()
            return .success(())
        } catch {
            return .failure(.network)
        }
    }

    /// Re-verify silently if the cached receipt is stale (keeps offline use working).
    func revalidateIfStale() async {
        guard state.isLicensed, let key = state.licenseKey, let at = state.verifiedAt else { return }
        if Date().timeIntervalSince(at) > LicenseConfig.reverifyAfterDays * 86_400 {
            _ = await activate(key: key)
        }
    }

    func deactivate() {
        state.licenseKey = nil; state.email = nil; state.verifiedAt = nil; state.uses = nil
        persist()
    }

    private func persist() { try? Self.encoder.encode(state).write(to: Self.fileURL, options: .atomic) }

    // MARK: machine binding

    static func machineID() -> String {
        let port: mach_port_t = kIOMainPortDefault
        let service = IOServiceGetMatchingService(port, IOServiceMatching("IOPlatformExpertDevice"))
        guard service != 0 else { return "unknown" }
        defer { IOObjectRelease(service) }
        guard let cf = IORegistryEntryCreateCFProperty(service, kIOPlatformUUIDKey as CFString, kCFAllocatorDefault, 0)?
            .takeRetainedValue() as? String else { return "unknown" }
        return cf
    }

    private static let encoder: JSONEncoder = {
        let e = JSONEncoder(); e.dateEncodingStrategy = .iso8601; e.outputFormatting = [.prettyPrinted]; return e
    }()
    private static let decoder: JSONDecoder = {
        let d = JSONDecoder(); d.dateDecodingStrategy = .iso8601; return d
    }()
}
