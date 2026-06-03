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

// 7. nav activator
check("default activator is rightCmd", Config.default.features.nav.activator.kind == "rightCmd")
do {
    let json = #"{ "features": { "nav": { "activator": { "kind": "rightAlt" } } } }"#
    let c = try ConfigStore.decode(Data(json.utf8))
    check("activator partial: kind override", c.features.nav.activator.kind == "rightAlt")
    check("activator partial: hotkey default filled", c.features.nav.activator.hotkey.key == "f12")
} catch { check("activator partial (no throw)", false) }

// 8. next / previous display
check("default nextDisplay = ⌃⌥right",
      Config.default.features.monitors.nextDisplay == KeyBinding(mods: ["ctrl", "alt"], key: "right"))
check("default prevDisplay = ⌃⌥left",
      Config.default.features.monitors.prevDisplay == KeyBinding(mods: ["ctrl", "alt"], key: "left"))

// 9. KeyNames mapping
check("keyName 123 -> left", KeyNames.keyName(forKeyCode: 123) == "left")
check("keyName 49 -> space", KeyNames.keyName(forKeyCode: 49) == "space")
check("keyName 8 -> c", KeyNames.keyName(forKeyCode: 8) == "c")
check("keyName fallback to characters", KeyNames.keyName(forKeyCode: 9999, characters: "X") == "x")
check("modifierNames cmd+option -> [alt,cmd]",
      KeyNames.modifierNames(rawFlags: (1 << 20) | (1 << 19)) == ["alt", "cmd"])
check("isModifierKeyCode 54 (rightcmd)", KeyNames.isModifierKeyCode(54))
check("isModifierKeyCode 8 (c) is false", !KeyNames.isModifierKeyCode(8))

// 10. curatedForEssentials clears unshown bindings
do {
    var c = Config.default
    c.features.cursor.enabled = true
    c.features.windows.enabled = true
    let cur = c.curatedForEssentials()
    check("curated: cursor off", !cur.features.cursor.enabled)
    check("curated: windows off", !cur.features.windows.enabled)
    check("curated: optionScroll off", !cur.features.monitors.optionScroll)
    check("curated: jumpClickKeys cleared", cur.features.monitors.jumpClickKeys.isEmpty)
    check("curated: parkKeys cleared", cur.features.monitors.parkKeys.isEmpty)
    check("curated: focusLeft cleared", cur.features.monitors.focusLeft.key.isEmpty)
    check("curated: jumpKeys preserved", cur.features.monitors.jumpKeys == ["1", "2", "3"])
    check("curated: nextDisplay preserved", cur.features.monitors.nextDisplay.key == "right")
}

print("\n\(pass) passed, \(fail) failed")
exit(fail == 0 ? 0 : 1)
