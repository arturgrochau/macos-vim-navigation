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

    public static func display(mods: [String], key: String) -> String {
        let m = order.filter { mods.contains($0) }.map { symbols[$0] ?? $0 }.joined()
        return m + key.uppercased()
    }

    private static func signature(_ mods: [String], _ key: String) -> String {
        order.filter { mods.contains($0) }.joined(separator: "+") + ":" + key.lowercased()
    }

    /// Returns one entry per signature that appears more than once in a namespace.
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
        if f.nav.enabled { for b in f.nav.enterKeys { addGlobal(b.mods, b.key) } }
        if f.monitors.enabled {
            for k in f.monitors.jumpKeys { addGlobal(["alt"], k) }
            for k in f.monitors.jumpClickKeys { addGlobal(["alt"], k) }
            for k in f.monitors.parkKeys { addGlobal(["alt"], k) }
            addGlobal(f.monitors.focusLeft.mods, f.monitors.focusLeft.key)
            addGlobal(f.monitors.focusRight.mods, f.monitors.focusRight.key)
        }
        if f.cursor.enabled {
            for k in [f.cursor.keys.left, f.cursor.keys.down, f.cursor.keys.up, f.cursor.keys.right, f.cursor.keys.click] {
                addGlobal(f.cursor.mods, k)
            }
        }
        if f.windows.enabled {
            addGlobal(f.windows.hide.mods, f.windows.hide.key)
            addGlobal(f.windows.restore.mods, f.windows.restore.key)
        }
        // Reload is always bound to ⌥R.
        addGlobal(["alt"], "r")

        // Modal (NAV MODE) keys.
        if f.nav.enabled { for b in f.nav.exitKeys { addModal(b.mods, b.key) } }
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
