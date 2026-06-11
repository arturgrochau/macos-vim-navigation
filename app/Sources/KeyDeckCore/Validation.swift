import Foundation

/// Detects duplicate key bindings. Hammerspoon has two independent binding
/// namespaces — global hotkeys (active anywhere) and modal keys (active only in
/// NAV MODE) — so a collision only matters within the same namespace.
public struct BindingConflict: Equatable {
    public let scope: String        // "Global" or "NAV MODE"
    public let signature: String    // human-readable, e.g. "⌥1"
    public let count: Int
}

public enum Validation {
    static let symbols: [String: String] = ["cmd": "⌘", "alt": "⌥", "ctrl": "⌃", "shift": "⇧"]
    static let order = ["ctrl", "alt", "shift", "cmd"]

    /// Keys the engine reserves inside NAV MODE (modules/nav.lua). A launcher
    /// assigned to one of these would silently shadow a navigation binding.
    public static let reservedNavKeys: Set<String> = [
        "h", "j", "k", "l",            // pointer movement
        "d", "u", "w", "b",            // scrolling
        "g",                           // gg / G scroll-to-edge
        "i", "a",                      // clicks
        "up", "down", "left", "right", // arrow equivalents
    ]
    /// Shift-modified keys reserved by NAV MODE (big moves/scrolls, focus
    /// cycling, center-mouse, the ? help overlay).
    public static let reservedShiftNavKeys: Set<String> = [
        "h", "j", "k", "l", "d", "u", "w", "b", "g", "a", "i", "m", "/",
    ]

    /// True when key+mods collides with a binding the engine itself owns in NAV MODE.
    public static func isReservedNavKey(key: String, mods: [String]) -> Bool {
        let k = key.lowercased()
        let m = Set(mods.map { $0.lowercased() })
        if m.isEmpty { return reservedNavKeys.contains(k) }
        if m == ["shift"] { return reservedShiftNavKeys.contains(k) }
        return false
    }

    public static func display(mods: [String], key: String) -> String {
        let m = order.filter { mods.contains($0) }.map { symbols[$0] ?? $0 }.joined()
        return m + key.uppercased()
    }

    private static func signature(_ mods: [String], _ key: String) -> String {
        order.filter { mods.contains($0) }.joined(separator: "+") + ":" + key.lowercased()
    }

    /// Returns one entry per signature that appears more than once in a namespace.
    /// The engine's own NAV MODE keys are seeded into the modal namespace, so a
    /// launcher on e.g. `j` is reported as a conflict.
    public static func conflicts(in config: Config) -> [BindingConflict] {
        var global: [(String, String)] = []   // (signature, display)
        var modal: [(String, String)] = []

        func addGlobal(_ mods: [String], _ key: String) {
            guard !key.isEmpty else { return }
            global.append((signature(mods, key), display(mods: mods, key: key)))
        }
        func addModal(_ mods: [String], _ key: String) {
            guard !key.isEmpty else { return }
            modal.append((signature(mods, key), display(mods: mods, key: key)))
        }

        let f = config.features
        // Global hotkeys.
        if f.nav.enabled {
            let a = f.nav.activator
            if a.kind == "hotkey" || a.kind == "hyper" { addGlobal(a.hotkey.mods, a.hotkey.key) }
            else if a.kind == "capsLock" { addGlobal([], "f18") }
            // tapModifier / doubleTapModifier are modifier taps — no normal-key conflict.
        }
        if f.monitors.enabled {
            for k in f.monitors.jumpKeys { addGlobal(["alt"], k) }
            for k in f.monitors.jumpClickKeys { addGlobal(["alt"], k) }
            for k in f.monitors.parkKeys { addGlobal(["alt"], k) }
            addGlobal(f.monitors.focusLeft.mods, f.monitors.focusLeft.key)
            addGlobal(f.monitors.focusRight.mods, f.monitors.focusRight.key)
            addGlobal(f.monitors.nextDisplay.mods, f.monitors.nextDisplay.key)
            addGlobal(f.monitors.prevDisplay.mods, f.monitors.prevDisplay.key)
        }

        // Modal (NAV MODE) keys: the engine's reserved keys, exit keys, launchers.
        if f.nav.enabled {
            for k in reservedNavKeys { addModal([], k) }
            for k in reservedShiftNavKeys { addModal(["shift"], k) }
            for b in f.nav.exitKeys { addModal(b.mods, b.key) }
        }
        for a in config.apps { addModal(a.mods, a.key) }

        return tally(global, scope: "Global") + tally(modal, scope: "NAV MODE")
    }

    private static func tally(_ items: [(String, String)], scope: String) -> [BindingConflict] {
        var counts: [String: (display: String, count: Int)] = [:]
        var firstSeenOrder: [String] = []
        for (sig, disp) in items {
            if counts[sig] == nil { firstSeenOrder.append(sig) }
            counts[sig, default: (disp, 0)].count += 1
        }
        return firstSeenOrder.compactMap { sig in
            let v = counts[sig]!
            return v.count > 1 ? BindingConflict(scope: scope, signature: v.display, count: v.count) : nil
        }
    }
}
