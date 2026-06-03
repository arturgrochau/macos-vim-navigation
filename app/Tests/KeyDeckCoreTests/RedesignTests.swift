import XCTest
@testable import KeyDeckCore

/// Tests for the redesign additions: nav activator, next/prev display, KeyNames, and
/// the curated-essentials save. (The XCTest-free runner in test/checks/main.swift mirrors
/// these so they also run under Command Line Tools.)
final class RedesignTests: XCTestCase {

    func testDefaultActivatorIsCtrlEquals() {
        let a = Config.default.features.nav.activator
        XCTAssertEqual(a.kind, "hotkey")
        XCTAssertEqual(a.hotkey, KeyBinding(mods: ["ctrl"], key: "="))
        XCTAssertEqual(a.modifier, "rightAlt")   // preserved for when user switches to a modifier trigger
    }

    func testActivatorPartialDecode() throws {
        let json = #"{ "features": { "nav": { "activator": { "kind": "doubleTapModifier" } } } }"#
        let c = try ConfigStore.decode(Data(json.utf8))
        XCTAssertEqual(c.features.nav.activator.kind, "doubleTapModifier")
        XCTAssertEqual(c.features.nav.activator.hotkey.key, "=")          // default filled
        XCTAssertEqual(c.features.nav.activator.modifier, "rightAlt")     // default filled
    }

    func testNextPrevDisplayDefaults() {
        XCTAssertEqual(Config.default.features.monitors.nextDisplay, KeyBinding(mods: ["ctrl", "alt"], key: "right"))
        XCTAssertEqual(Config.default.features.monitors.prevDisplay, KeyBinding(mods: ["ctrl", "alt"], key: "left"))
    }

    func testKeyNames() {
        XCTAssertEqual(KeyNames.keyName(forKeyCode: 123), "left")
        XCTAssertEqual(KeyNames.keyName(forKeyCode: 49), "space")
        XCTAssertEqual(KeyNames.keyName(forKeyCode: 8), "c")
        XCTAssertEqual(KeyNames.keyName(forKeyCode: 9999, characters: "X"), "x")
        XCTAssertEqual(KeyNames.modifierNames(rawFlags: (1 << 20) | (1 << 19)), ["alt", "cmd"])
        XCTAssertTrue(KeyNames.isModifierKeyCode(54))
        XCTAssertFalse(KeyNames.isModifierKeyCode(8))
    }

    func testCuratedForEssentials() {
        var c = Config.default
        c.features.cursor.enabled = true
        c.features.windows.enabled = true
        let cur = c.curatedForEssentials()
        XCTAssertTrue(cur.features.cursor.enabled)   // Advanced-controlled, preserved
        XCTAssertFalse(cur.features.windows.enabled)
        XCTAssertFalse(cur.features.monitors.optionScroll)
        XCTAssertTrue(cur.features.monitors.jumpClickKeys.isEmpty)
        XCTAssertTrue(cur.features.monitors.parkKeys.isEmpty)
        XCTAssertTrue(cur.features.monitors.focusLeft.key.isEmpty)
        XCTAssertEqual(cur.features.monitors.jumpKeys, ["1", "2", "3"])     // preserved
        XCTAssertEqual(cur.features.monitors.nextDisplay.key, "right")      // preserved
    }

    func testMiscDefaults() {
        XCTAssertFalse(Config.default.features.monitors.optionTapCycle)
        XCTAssertEqual(KeyNames.keyName(forKeyCode: 79), "f18")
        XCTAssertFalse(Config.default.debug)
        XCTAssertTrue(Config.default.customLua.isEmpty)
    }

    func testSuggestedLaunchers() {
        let installed = [("com.openai.chat", "ChatGPT"), ("company.thebrowser.Browser", "Arc"), ("com.apple.Terminal", "Terminal")]
        let s = SuggestedLaunchers.suggestions(installed: installed)
        XCTAssertTrue(s.contains { $0.key == "c" && $0.bundleID == "com.openai.chat" })
        XCTAssertTrue(s.contains { $0.key == "b" && $0.bundleID == "company.thebrowser.Browser" })
        XCTAssertTrue(s.contains { $0.key == "g" })   // Terminal
        let keys = SuggestedLaunchers.catalog.map { $0.key }
        XCTAssertEqual(Set(keys).count, keys.count)
    }

    func testConflictHelper() {
        let c = Config.default
        XCTAssertNotNil(c.appLauncherName(forKey: "c", mods: [], excludingID: nil))
        XCTAssertNil(c.appLauncherName(forKey: "z", mods: [], excludingID: nil))
    }

    func testFreemiumEntitlements() {
        XCTAssertFalse(LicenseState.free.isPro)
        var licensed = LicenseState.free
        licensed.licenseKey = "KEY"; licensed.verifiedAt = Date(timeIntervalSince1970: 1)
        XCTAssertTrue(licensed.isPro)
        XCTAssertFalse(Entitlements.canAddLauncher(currentCount: 5, isPro: false))
        XCTAssertTrue(Entitlements.canAddLauncher(currentCount: 4, isPro: false))
        XCTAssertTrue(Entitlements.canAddLauncher(currentCount: 999, isPro: true))
        XCTAssertFalse(Entitlements.displayCustomizationAllowed(isPro: false))
        XCTAssertTrue(Entitlements.displayCustomizationAllowed(isPro: true))
    }

    func testEngineStatusDecode() throws {
        let json = #"{ "loadedAt": 1700000000, "preset": "default", "navEnabled": true }"#
        let s = try JSONDecoder().decode(EngineStatus.self, from: Data(json.utf8))
        XCTAssertEqual(s.loadedAt, 1_700_000_000)
        XCTAssertTrue(s.navEnabled)
    }

    func testPersistenceRoundTrip() throws {
        var c = Config.default
        c.apps = [AppShortcut(key: "x", mods: [], bundleID: "com.x.y", names: ["X"])]
        c.features.nav.activator = NavActivator(kind: "doubleTapModifier", modifier: "alt")
        let restored = try ConfigStore.decode(try ConfigStore.encode(c))
        XCTAssertEqual(restored, c)
        XCTAssertEqual(restored.apps.first?.key, "x")
        XCTAssertEqual(restored.features.nav.activator.kind, "doubleTapModifier")
    }
}
