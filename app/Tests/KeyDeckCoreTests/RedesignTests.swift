import XCTest
@testable import KeyDeckCore

/// Tests for the redesign additions: nav activator, next/prev display, KeyNames, and
/// the curated-essentials save. (The XCTest-free runner in test/checks/main.swift mirrors
/// these so they also run under Command Line Tools.)
final class RedesignTests: XCTestCase {

    func testDefaultActivatorIsRightCmd() {
        XCTAssertEqual(Config.default.features.nav.activator.kind, "rightCmd")
    }

    func testActivatorPartialDecode() throws {
        let json = #"{ "features": { "nav": { "activator": { "kind": "rightAlt" } } } }"#
        let c = try ConfigStore.decode(Data(json.utf8))
        XCTAssertEqual(c.features.nav.activator.kind, "rightAlt")
        XCTAssertEqual(c.features.nav.activator.hotkey.key, "f12")  // default filled
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
        XCTAssertFalse(cur.features.cursor.enabled)
        XCTAssertFalse(cur.features.windows.enabled)
        XCTAssertFalse(cur.features.monitors.optionScroll)
        XCTAssertTrue(cur.features.monitors.jumpClickKeys.isEmpty)
        XCTAssertTrue(cur.features.monitors.parkKeys.isEmpty)
        XCTAssertTrue(cur.features.monitors.focusLeft.key.isEmpty)
        XCTAssertEqual(cur.features.monitors.jumpKeys, ["1", "2", "3"])     // preserved
        XCTAssertEqual(cur.features.monitors.nextDisplay.key, "right")      // preserved
    }
}
