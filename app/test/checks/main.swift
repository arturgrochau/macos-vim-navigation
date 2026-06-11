// Standalone runner: compiled together with the KeyDeckCore sources as one module
// (so no `import` needed) to actually EXECUTE the core logic assertions without
// needing XCTest/SwiftPM linking. Mirrors Tests/KeyDeckCoreTests/.
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
    let json = #"{ "features": { "monitors": { "cycleModifier": "ctrl" } } }"#
    let c = try ConfigStore.decode(Data(json.utf8))
    check("partial: cycleModifier override applied", c.features.monitors.cycleModifier == "ctrl")
    check("partial: scrollStep default filled", c.tuning.scrollStep == 62)
    check("partial: nav default filled", c.features.nav.enabled)
    check("partial: optionTapCycle default true", c.features.monitors.optionTapCycle)
} catch { check("partial decode (no throw)", false) }

// 3. OLD config with removed feature blocks decodes cleanly (keys are ignored)
do {
    let json = #"""
    { "features": { "visual": { "enabled": true },
                    "cursor": { "enabled": true, "keys": { "left": "h" } },
                    "windows": { "enabled": true } },
      "tuning": { "globalCursorStep": 180, "dragMoveFrac": 0.05, "scrollStep": 70 },
      "apps": [ { "key": "c", "bundleID": "com.openai.chat", "names": ["ChatGPT"] } ] }
    """#
    let c = try ConfigStore.decode(Data(json.utf8))
    check("old config: decodes despite removed blocks", true)
    check("old config: known keys still applied", c.tuning.scrollStep == 70 && c.apps.count == 1)
} catch { check("old config decode (no throw)", false) }

// 4. KeyBinding partial decode
do {
    let b = try JSONDecoder().decode(KeyBinding.self, from: Data(#"{ "key": "x" }"#.utf8))
    check("keybinding partial: key", b.key == "x")
    check("keybinding partial: mods default []", b.mods == [])
}
// (decode of a well-formed literal; failure would surface as a thrown error above)

// 5. conflicts
check("default has no conflicts", Validation.conflicts(in: .default).isEmpty)
do {
    var c = Config.default
    c.apps = [AppShortcut(key: "c", bundleID: "a"), AppShortcut(key: "c", bundleID: "b")]
    check("duplicate launcher key detected",
          Validation.conflicts(in: c).contains { $0.scope == "NAV MODE" && $0.signature == "C" })
}
do {
    var c = Config.default
    c.apps = [AppShortcut(key: "j", bundleID: "a")]
    check("launcher on reserved nav key (j) detected",
          Validation.conflicts(in: c).contains { $0.scope == "NAV MODE" && $0.signature == "J" })
    check("isReservedNavKey: bare j", Validation.isReservedNavKey(key: "j", mods: []))
    check("isReservedNavKey: shift+m", Validation.isReservedNavKey(key: "m", mods: ["shift"]))
    check("isReservedNavKey: bare z is free", !Validation.isReservedNavKey(key: "z", mods: []))
}
do {
    var c = Config.default
    c.features.monitors.jumpKeys = ["1", "1"]
    check("duplicate global binding detected (⌥1)",
          Validation.conflicts(in: c).contains { $0.scope == "Global" && $0.signature == "⌥1" })
}

// 6. encoded JSON omits id; display formatting
do {
    var c = Config.default
    c.apps = [AppShortcut(key: "c", bundleID: "com.openai.chat", names: ["ChatGPT"])]
    let str = String(decoding: try ConfigStore.encode(c), as: UTF8.self)
    check("encoded JSON omits app id", !str.contains("\"id\""))
    check("encoded JSON has bundle id", str.contains("com.openai.chat"))
} catch { check("encode (no throw)", false) }
check("display ⌥⇧⌘H", Validation.display(mods: ["alt", "cmd", "shift"], key: "h") == "⌥⇧⌘H")
check("display bare C", Validation.display(mods: [], key: "c") == "C")

// 7. nav activator
check("default activator is hotkey ⌃=",
      Config.default.features.nav.activator.kind == "hotkey"
      && Config.default.features.nav.activator.hotkey == KeyBinding(mods: ["ctrl"], key: "="))
do {
    let json = #"{ "features": { "nav": { "activator": { "kind": "doubleTapModifier" } } } }"#
    let c = try ConfigStore.decode(Data(json.utf8))
    check("activator partial: kind override", c.features.nav.activator.kind == "doubleTapModifier")
    check("activator partial: hotkey default filled", c.features.nav.activator.hotkey.key == "=")
} catch { check("activator partial (no throw)", false) }

// 8. curated() clears every monitor sub-binding the UI doesn't surface
do {
    let cur = Config.default.curated()
    check("curated: jumpKeys cleared", cur.features.monitors.jumpKeys.isEmpty)
    check("curated: jumpClickKeys cleared", cur.features.monitors.jumpClickKeys.isEmpty)
    check("curated: parkKeys cleared", cur.features.monitors.parkKeys.isEmpty)
    check("curated: focusLeft cleared", cur.features.monitors.focusLeft.key.isEmpty)
    check("curated: nextDisplay cleared", cur.features.monitors.nextDisplay.key.isEmpty)
    check("curated: optionScroll off", !cur.features.monitors.optionScroll)
    check("curated: cycle toggle preserved", cur.features.monitors.optionTapCycle)
    check("curated: cycleModifier preserved", cur.features.monitors.cycleModifier == "alt")
}

// 9. misc defaults
check("default optionTapCycle is true", Config.default.features.monitors.optionTapCycle)
check("default cycleModifier is alt", Config.default.features.monitors.cycleModifier == "alt")
check("default apps list is empty", Config.default.apps.isEmpty)
check("default debug is false", !Config.default.debug)
check("default customLua is empty", Config.default.customLua.isEmpty)

// 10. KeyNames mapping
check("keyName 123 -> left", KeyNames.keyName(forKeyCode: 123) == "left")
check("keyName 49 -> space", KeyNames.keyName(forKeyCode: 49) == "space")
check("keyName 8 -> c", KeyNames.keyName(forKeyCode: 8) == "c")
check("keyName fallback to characters", KeyNames.keyName(forKeyCode: 9999, characters: "X") == "x")
check("keyName 79 -> f18", KeyNames.keyName(forKeyCode: 79) == "f18")
check("modifierNames cmd+option -> [alt,cmd]",
      KeyNames.modifierNames(rawFlags: (1 << 20) | (1 << 19)) == ["alt", "cmd"])
check("isModifierKeyCode 54 (rightcmd)", KeyNames.isModifierKeyCode(54))
check("isModifierKeyCode 8 (c) is false", !KeyNames.isModifierKeyCode(8))

// 11. SuggestedLaunchers
do {
    let installed = [("com.openai.chat", "ChatGPT"), ("company.thebrowser.Browser", "Arc"), ("com.apple.Terminal", "Terminal")]
    let s = SuggestedLaunchers.suggestions(installed: installed)
    check("suggest: ChatGPT on c", s.contains { $0.key == "c" && $0.bundleID == "com.openai.chat" })
    check("suggest: Browser on o", s.contains { $0.key == "o" && $0.bundleID == "company.thebrowser.Browser" })
    check("suggest: Terminal on x", s.contains { $0.key == "x" })
    let keys = SuggestedLaunchers.catalog.map { $0.key }
    check("catalog keys are unique", Set(keys).count == keys.count)
    check("no suggested key is nav-reserved",
          s.allSatisfy { !Validation.isReservedNavKey(key: $0.key, mods: $0.mods) })
}

// 12. conflict helper
do {
    var c = Config.default
    c.apps = [AppShortcut(key: "c", bundleID: "com.openai.chat", names: ["ChatGPT"])]
    check("conflict: bare c is taken", c.appLauncherName(forKey: "c", mods: [], excludingID: nil) != nil)
    check("conflict: bare z is free", c.appLauncherName(forKey: "z", mods: [], excludingID: nil) == nil)
}

// 13. License + trial entitlements
do {
    let free = LicenseState.free
    check("free state: not Pro", !free.isPro)
    var licensed = free
    licensed.licenseKey = "KEY"; licensed.verifiedAt = Date(timeIntervalSince1970: 1)
    check("licensed: isPro", licensed.isPro)

    let now = Date(timeIntervalSince1970: 1_700_000_000)
    let dayN = { (n: Double) in now.addingTimeInterval(-n * 86_400) }
    check("tier: licensed -> pro", Entitlements.tier(isLicensed: true, firstLaunch: dayN(100), now: now) == .pro)
    check("tier: fresh install -> trial 14",
          Entitlements.tier(isLicensed: false, firstLaunch: now, now: now) == .trial(daysLeft: 14))
    check("tier: day 13 -> trial 1",
          Entitlements.tier(isLicensed: false, firstLaunch: dayN(13.5), now: now) == .trial(daysLeft: 1))
    check("tier: day 14 -> free",
          Entitlements.tier(isLicensed: false, firstLaunch: dayN(14.5), now: now) == .free)

    check("entitlements: trial can add unlimited", Entitlements.canAddLauncher(currentCount: 99, tier: .trial(daysLeft: 3)))
    check("entitlements: pro unlimited", Entitlements.canAddLauncher(currentCount: 999, tier: .pro))
    check("entitlements: free caps at 3", !Entitlements.canAddLauncher(currentCount: 3, tier: .free))
    check("entitlements: free can add a 3rd (had 2)", Entitlements.canAddLauncher(currentCount: 2, tier: .free))
}

// 14. license.json written before trials existed still decodes
do {
    let json = #"{ "licenseKey": "K", "verifiedAt": "2025-01-01T00:00:00Z" }"#
    let d = JSONDecoder(); d.dateDecodingStrategy = .iso8601
    let s = try d.decode(LicenseState.self, from: Data(json.utf8))
    check("old license.json decodes (no firstLaunchAt)", s.firstLaunchAt == nil && s.isPro)
} catch { check("old license.json decodes (no throw)", false) }

// 15. EngineStatus decode
do {
    let json = #"{ "loadedAt": 1700000000, "preset": "default", "navEnabled": true }"#
    let s = try JSONDecoder().decode(EngineStatus.self, from: Data(json.utf8))
    check("EngineStatus decodes loadedAt", s.loadedAt == 1_700_000_000)
    check("EngineStatus decodes navEnabled", s.navEnabled)
} catch { check("EngineStatus decode (no throw)", false) }

// 16. persistence round-trip ("restart" = encode then decode)
do {
    var c = Config.default
    c.apps = [AppShortcut(key: "x", mods: [], bundleID: "com.x.y", names: ["X"], clickTarget: "center", exitNav: true)]
    c.features.nav.activator = NavActivator(kind: "hotkey", hotkey: KeyBinding(mods: ["ctrl", "alt"], key: "n"))
    c.features.monitors.cycleModifier = "ctrl"
    let restored = try ConfigStore.decode(try ConfigStore.encode(c))
    check("persistence: config round-trips unchanged", restored == c)
    check("persistence: app mapping persists", restored.apps.first?.key == "x")
    check("persistence: cycleModifier persists", restored.features.monitors.cycleModifier == "ctrl")
} catch { check("persistence round-trip (no throw)", false) }

print("\n\(pass) passed, \(fail) failed")
exit(fail == 0 ? 0 : 1)
