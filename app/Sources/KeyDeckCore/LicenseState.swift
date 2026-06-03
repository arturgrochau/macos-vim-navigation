import Foundation

/// Persistent license/trial state (pure & testable). The app layer fills `machineID`,
/// performs Gumroad verification, and reads/writes this to disk; this type only owns the
/// data and the gating logic.
public struct LicenseState: Codable, Equatable {
    public static let trialDays = 14

    public var trialStart: Date
    public var licenseKey: String?
    public var email: String?
    public var machineID: String?
    public var verifiedAt: Date?
    public var uses: Int?

    public init(trialStart: Date, licenseKey: String? = nil, email: String? = nil,
                machineID: String? = nil, verifiedAt: Date? = nil, uses: Int? = nil) {
        self.trialStart = trialStart
        self.licenseKey = licenseKey
        self.email = email
        self.machineID = machineID
        self.verifiedAt = verifiedAt
        self.uses = uses
    }

    /// A fresh trial starting now.
    public static func startingTrial(now: Date) -> LicenseState { LicenseState(trialStart: now) }

    public var isLicensed: Bool {
        guard let key = licenseKey else { return false }
        return !key.isEmpty && verifiedAt != nil
    }

    /// Whole days left in the trial (0 once expired).
    public func daysLeftInTrial(now: Date) -> Int {
        let end = trialStart.addingTimeInterval(Double(Self.trialDays) * 86_400)
        let remaining = end.timeIntervalSince(now)
        if remaining <= 0 { return 0 }
        return Int(ceil(remaining / 86_400))
    }

    public func trialActive(now: Date) -> Bool { daysLeftInTrial(now: now) > 0 }

    /// The editor may save/Apply while licensed or during the trial.
    public func isApplyAllowed(now: Date) -> Bool { isLicensed || trialActive(now: now) }

    /// Short human status for the footer.
    public func statusText(now: Date) -> String {
        if isLicensed { return "Licensed" + (email.map { " · \($0)" } ?? "") }
        let d = daysLeftInTrial(now: now)
        return d > 0 ? "Trial · \(d) day\(d == 1 ? "" : "s") left" : "Trial expired — license required to Apply"
    }
}
