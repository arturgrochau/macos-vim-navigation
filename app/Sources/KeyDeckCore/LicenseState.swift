import Foundation

/// Persistent license state (pure & testable). Freemium model: the app is always
/// usable and Apply always works; a Gumroad license unlocks Pro (unlimited mappings
/// + display customization). The app layer fills `machineID`, performs Gumroad
/// verification, and reads/writes this to disk.
public struct LicenseState: Codable, Equatable {
    public var licenseKey: String?
    public var email: String?
    public var machineID: String?
    public var verifiedAt: Date?
    public var uses: Int?

    public init(licenseKey: String? = nil, email: String? = nil, machineID: String? = nil,
                verifiedAt: Date? = nil, uses: Int? = nil) {
        self.licenseKey = licenseKey
        self.email = email
        self.machineID = machineID
        self.verifiedAt = verifiedAt
        self.uses = uses
    }

    public static let free = LicenseState()

    public var isPro: Bool {
        guard let key = licenseKey else { return false }
        return !key.isEmpty && verifiedAt != nil
    }

    public func statusText() -> String {
        isPro ? "Pro" + (email.map { " · \($0)" } ?? "") : "Free Plan"
    }
}
