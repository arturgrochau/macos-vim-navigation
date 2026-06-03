import Foundation

/// Makes Caps Lock usable as the Nav Mode trigger by remapping Caps Lock → F18
/// (which the engine binds). Uses `hidutil` for the live remap and a LaunchAgent so
/// it persists across reboots. Fully reversible.
enum CapsLockSetup {
    private static let label = "com.arturgrochau.keydeck.capslock"
    // HID usages: Caps Lock = 0x700000039, F18 = 0x70000006D.
    private static let mapJSON =
        #"{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":0x700000039,"HIDKeyboardModifierMappingDst":0x70000006D}]}"#

    private static var plistURL: URL {
        FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("LaunchAgents/\(label).plist")
    }

    static var isEnabled: Bool { FileManager.default.fileExists(atPath: plistURL.path) }

    /// Apply the remap now and install the LaunchAgent.
    @discardableResult
    static func enable() -> Bool {
        run("/usr/bin/hidutil", ["property", "--set", mapJSON])
        let plist = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0"><dict>
          <key>Label</key><string>\(label)</string>
          <key>ProgramArguments</key>
          <array><string>/usr/bin/hidutil</string><string>property</string><string>--set</string><string>\(mapJSON)</string></array>
          <key>RunAtLoad</key><true/>
        </dict></plist>
        """
        do {
            try FileManager.default.createDirectory(
                at: plistURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try plist.write(to: plistURL, atomically: true, encoding: .utf8)
            run("/bin/launchctl", ["load", "-w", plistURL.path])
            return true
        } catch { return false }
    }

    /// Revert the remap and remove the LaunchAgent.
    static func disable() {
        run("/bin/launchctl", ["unload", "-w", plistURL.path])
        try? FileManager.default.removeItem(at: plistURL)
        run("/usr/bin/hidutil", ["property", "--set", #"{"UserKeyMapping":[]}"#])
    }

    @discardableResult
    private static func run(_ path: String, _ args: [String]) -> Bool {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: path)
        p.arguments = args
        do { try p.run(); p.waitUntilExit(); return p.terminationStatus == 0 } catch { return false }
    }
}
