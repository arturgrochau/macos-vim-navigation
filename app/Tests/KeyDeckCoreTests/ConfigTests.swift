import XCTest
@testable import KeyDeckCore

final class ConfigTests: XCTestCase {

    func testDefaultRoundTrips() throws {
        let data = try ConfigStore.encode(.default)
        let decoded = try ConfigStore.decode(data)
        XCTAssertEqual(decoded, .default)
    }

    func testPartialConfigFillsDefaults() throws {
        // Only flips one nested flag; everything else must fall back to defaults.
        let json = #"{ "features": { "cursor": { "enabled": true } } }"#
        let c = try ConfigStore.decode(Data(json.utf8))
        XCTAssertTrue(c.features.cursor.enabled)             // override applied
        XCTAssertEqual(c.tuning.scrollStep, 62)              // default filled
        XCTAssertTrue(c.features.nav.enabled)                // default filled
        XCTAssertEqual(c.apps, Config.default.apps)          // default apps preserved
        XCTAssertEqual(c.features.cursor.keys.left, "h")     // nested default filled
    }

    func testKeyBindingPartialDecode() throws {
        let b = try JSONDecoder().decode(KeyBinding.self, from: Data(#"{ "key": "x" }"#.utf8))
        XCTAssertEqual(b.key, "x")
        XCTAssertEqual(b.mods, [])
    }

    func testDeveloperPreset() {
        let c = Config.preset(named: "developer")
        XCTAssertEqual(c.preset, "developer")
        XCTAssertTrue(c.features.cursor.enabled)
        XCTAssertTrue(c.features.windows.enabled)
        XCTAssertTrue(c.apps.contains { $0.bundleID == "com.anthropic.claudefordesktop" })
    }

    func testMinimalPreset() {
        let c = Config.preset(named: "minimal")
        XCTAssertFalse(c.features.visual.enabled)
        XCTAssertTrue(c.apps.isEmpty)
        XCTAssertTrue(c.features.monitors.jumpClickKeys.isEmpty)
        XCTAssertTrue(c.features.monitors.enabled)           // monitors stay on
    }

    func testDefaultHasNoConflicts() {
        XCTAssertTrue(Validation.conflicts(in: .default).isEmpty,
                      "default preset should not self-conflict")
    }

    func testDuplicateModalBindingDetected() {
        var c = Config.default
        c.apps.append(AppShortcut(key: "c"))   // duplicates ChatGPT's bare `c`
        let conflicts = Validation.conflicts(in: c)
        XCTAssertTrue(conflicts.contains { $0.scope == "NAV MODE" && $0.signature == "C" })
    }

    func testDuplicateGlobalBindingDetected() {
        var c = Config.default
        // Make a monitor jump key collide with the reload key (⌥R).
        c.features.monitors.jumpKeys = ["r"]
        let conflicts = Validation.conflicts(in: c)
        XCTAssertTrue(conflicts.contains { $0.scope == "Global" && $0.signature == "⌥R" })
    }

    func testEncodedJSONOmitsAppID() throws {
        let data = try ConfigStore.encode(.default)
        let str = String(decoding: data, as: UTF8.self)
        XCTAssertFalse(str.contains("\"id\""), "app id must not be serialized")
        XCTAssertTrue(str.contains("com.openai.chat"))
    }

    func testDisplayFormatting() {
        XCTAssertEqual(Validation.display(mods: ["alt", "cmd", "shift"], key: "h"), "⌥⇧⌘H")
        XCTAssertEqual(Validation.display(mods: [], key: "c"), "C")
    }
}
