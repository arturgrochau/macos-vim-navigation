import Foundation

/// Freemium limits. Free is fully functional within these caps; Pro lifts them.
public enum Entitlements {
    public static let freeMaxLaunchers = 5

    public static func maxLaunchers(isPro: Bool) -> Int { isPro ? Int.max : freeMaxLaunchers }

    /// May the user add another launcher given how many they already have?
    public static func canAddLauncher(currentCount: Int, isPro: Bool) -> Bool {
        isPro || currentCount < freeMaxLaunchers
    }

    /// Display customization (next/prev cycling, custom keys) is a Pro feature.
    /// Free users get the three default jumps (⌥1/⌥2/⌥3).
    public static func displayCustomizationAllowed(isPro: Bool) -> Bool { isPro }
}
