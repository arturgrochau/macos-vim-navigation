import Foundation
import KeyDeckCore

/// Installs/repairs the KeyDeck engine as a Hammerspoon Spoon that coexists with the
/// user's own config: copies KeyDeck.spoon into ~/.hammerspoon/Spoons, backs up
/// init.lua, and appends a 2-line loader. Also reports engine health.
enum EngineInstaller {
    enum Health: Equatable {
        case active                // engine loaded recently (heartbeat fresh)
        case installedNotLoaded    // spoon present but no recent heartbeat
        case notInstalled          // spoon missing
        case noHammerspoon         // Hammerspoon.app not found
    }

    private static var fm: FileManager { .default }
    private static var home: String { NSHomeDirectory() }
    private static var hsDir: String { (home as NSString).appendingPathComponent(".hammerspoon") }
    private static var initLua: String { (hsDir as NSString).appendingPathComponent("init.lua") }
    private static var spoonDest: String { (hsDir as NSString).appendingPathComponent("Spoons/KeyDeck.spoon") }
    private static let loaderMarker = "-- KeyDeck (added by the KeyDeck app)"
    private static let loader = """

    -- KeyDeck (added by the KeyDeck app)
    hs.loadSpoon("KeyDeck")
    spoon.KeyDeck:start()
    """

    static func health() -> Health {
        if !fm.fileExists(atPath: "/Applications/Hammerspoon.app") { return .noHammerspoon }
        if let s = EngineStatus.read(), Date().timeIntervalSince1970 - s.loadedAt < 600 { return .active }
        return fm.fileExists(atPath: (spoonDest as NSString).appendingPathComponent("init.lua"))
            ? .installedNotLoaded : .notInstalled
    }

    /// Install (or refresh) the spoon and wire it into init.lua. Returns nil on success
    /// or an error message.
    @discardableResult
    static func install() -> String? {
        do {
            try assembleSpoon(into: spoonDest)
            try fm.createDirectory(atPath: hsDir, withIntermediateDirectories: true)
            // Back up the user's init.lua once.
            if fm.fileExists(atPath: initLua) {
                let backup = initLua + ".keydeck-backup"
                if !fm.fileExists(atPath: backup) { try? fm.copyItem(atPath: initLua, toPath: backup) }
            }
            // Append the loader if it isn't already there.
            var contents = (try? String(contentsOfFile: initLua, encoding: .utf8)) ?? ""
            if !contents.contains(loaderMarker) {
                contents += loader + "\n"
                try contents.write(toFile: initLua, atomically: true, encoding: .utf8)
            }
            relaunchHammerspoon()   // reliable first-load trigger
            return nil
        } catch {
            return error.localizedDescription
        }
    }

    /// Reload via URL — works once the engine has registered its handler (post-setup).
    static func reloadHammerspoon() {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        p.arguments = ["-g", "hammerspoon://reload"]
        try? p.run()
    }

    /// Quit + relaunch Hammerspoon — the dependable way to load the engine the FIRST
    /// time, before the engine's reload URL handler exists.
    static func relaunchHammerspoon() {
        let quit = Process()
        quit.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        quit.arguments = ["-e", "tell application \"Hammerspoon\" to quit"]
        try? quit.run(); quit.waitUntilExit()
        let open = Process()
        open.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        open.arguments = ["-g", "-a", "Hammerspoon"]
        try? open.run()
    }

    /// Engine error captured by the spoon on its last load attempt, if any.
    static func lastError() -> String? {
        let path = (NSHomeDirectory() as NSString)
            .appendingPathComponent("Library/Application Support/KeyDeck/engine-error.txt")
        guard let s = try? String(contentsOfFile: path, encoding: .utf8) else { return nil }
        let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }

    // MARK: assembling the spoon

    /// Copy the engine into a self-contained spoon directory. Prefers a pre-assembled
    /// spoon bundled in the app; falls back to assembling from the repo (dev).
    private static func assembleSpoon(into dest: String) throws {
        if fm.fileExists(atPath: dest) { try fm.removeItem(atPath: dest) }
        try fm.createDirectory(atPath: dest, withIntermediateDirectories: true)

        if let bundled = Bundle.main.url(forResource: "KeyDeck", withExtension: "spoon"),
           fm.fileExists(atPath: bundled.appendingPathComponent("defaults.lua").path) {
            try copyContents(of: bundled.path, into: dest)
            return
        }

        // Dev fallback: copy the canonical Spoon from the repo tree relative to this file.
        let root = URL(fileURLWithPath: #filePath)       // app/Sources/KeyDeck/EngineInstaller.swift
            .deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()  // -> repo root
        try copyContents(of: root.appendingPathComponent("Spoons/KeyDeck.spoon").path, into: dest)
    }

    private static func copyContents(of src: String, into dest: String) throws {
        for item in (try? fm.contentsOfDirectory(atPath: src)) ?? [] {
            try fm.copyItem(atPath: (src as NSString).appendingPathComponent(item),
                            toPath: (dest as NSString).appendingPathComponent(item))
        }
    }
}
