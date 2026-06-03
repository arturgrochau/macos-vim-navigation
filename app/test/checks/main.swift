// Standalone runner: compiled together with the KeyDeckCore sources as one module
// (so no `import` needed) to actually EXECUTE the core logic assertions without
// needing XCTest/SwiftPM linking. Mirrors Tests/KeyDeckCoreTests/ConfigTests.swift.
import Foundation

var pass = 0, fail = 0
func check(_ name: String, _ cond: Bool) {
    if cond { pass += 1; print("  ok   \(name)") }
    else { fail += 1; print("  FAIL \(name)") }
}

// 1. default round-trips
do {
    let data = try ConfigStore.encode(.default)
    let decoded = try ConfigStore.decode(data)
    check("default round-trips", decoded == .default)
} catch { check("default round-trips (no throw)", false) }

// 2. partial config fills defaults
do {
    let json = #"{ "features": { "cursor": { "enabled": true } } }"#
    let c = try ConfigStore.decode(Data(json.utf8))
    check("partial: cursor override applied", c.features.cursor.enabled)
    check("partial: scrollStep default filled", c.tuning.scrollStep == 62)
    check("partial: nav default filled", c.features.nav.enabled)
    check("partial: apps default preserved", c.apps == Config.default.apps)
    check("partial: nested cursor key default", c.features.cursor.keys.left == "h")
} catch { check("partial decode (no throw)", false) }

// 3. KeyBinding partial decode
do {
    let b = try JSONDecoder().decode(KeyBinding.self, from: Data(#"{ "key": "x" }"#.utf8))
    check("keybinding partial: key", b.key == "x")
    check("keybinding partial: mods default []", b.mods == [])
} catch { check("keybinding partial (no throw)", false) }

// 4. presets
let dev = Config.preset(named: "developer")
check("developer: cursor on", dev.features.cursor.enabled)
check("developer: windows on", dev.features.windows.enabled)
check("developer: has Claude", dev.apps.contains { $0.bundleID == "com.anthropic.claudefordesktop" })
let min = Config.preset(named: "minimal")
check("minimal: visual off", !min.features.visual.enabled)
check("minimal: apps empty", min.apps.isEmpty)
check("minimal: monitors still on", min.features.monitors.enabled)

// 5. conflicts
check("default has no conflicts", Validation.conflicts(in: .default).isEmpty)
do {
    var c = Config.default
    c.apps.append(AppShortcut(key: "c"))
    check("duplicate modal binding detected",
          Validation.conflicts(in: c).contains { $0.scope == "NAV MODE" && $0.signature == "C" })
}
do {
    var c = Config.default
    c.features.monitors.jumpKeys = ["r"]
    check("duplicate global binding detected (⌥R)",
          Validation.conflicts(in: c).contains { $0.scope == "Global" && $0.signature == "⌥R" })
}

// 6. encoded JSON omits id; display formatting
do {
    let str = String(decoding: try ConfigStore.encode(.default), as: UTF8.self)
    check("encoded JSON omits app id", !str.contains("\"id\""))
    check("encoded JSON has bundle id", str.contains("com.openai.chat"))
} catch { check("encode (no throw)", false) }
check("display ⌥⇧⌘H", Validation.display(mods: ["alt", "cmd", "shift"], key: "h") == "⌥⇧⌘H")
check("display bare C", Validation.display(mods: [], key: "c") == "C")

print("\n\(pass) passed, \(fail) failed")
exit(fail == 0 ? 0 : 1)
