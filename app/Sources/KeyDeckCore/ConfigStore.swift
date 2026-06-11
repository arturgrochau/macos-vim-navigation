import Foundation

/// Reads and writes the engine config at ~/.hammerspoon/keydeck-config.json and
/// triggers a Hammerspoon reload. The engine also auto-reloads via a pathwatcher,
/// so writing the file is sufficient; `reload()` just makes it instant.
public enum ConfigStore {
    public static var path: String {
        (NSHomeDirectory() as NSString).appendingPathComponent(".hammerspoon/keydeck-config.json")
    }

    public static var fileExists: Bool { FileManager.default.fileExists(atPath: path) }

    /// Load the config file, or the built-in default if absent/unreadable.
    public static func load() -> Config {
        guard let data = FileManager.default.contents(atPath: path) else { return .default }
        return (try? decoder().decode(Config.self, from: data)) ?? .default
    }

    /// Decode a Config from raw JSON data (used by tests and previews).
    public static func decode(_ data: Data) throws -> Config {
        try decoder().decode(Config.self, from: data)
    }

    /// Serialize a Config to pretty, stable JSON.
    public static func encode(_ config: Config) throws -> Data {
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return try enc.encode(config)
    }

    /// Write the config to disk (creating ~/.hammerspoon if needed).
    public static func save(_ config: Config) throws {
        let dir = (path as NSString).deletingLastPathComponent
        try FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        try encode(config).write(to: URL(fileURLWithPath: path), options: .atomic)
    }

    /// Ask a running Hammerspoon to reload immediately (best-effort).
    public static func reload() {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        p.arguments = ["-g", "hammerspoon://reload"]
        try? p.run()
    }

    /// Save then reload.
    public static func apply(_ config: Config) throws {
        try save(config)
        reload()
    }

    private static func decoder() -> JSONDecoder { JSONDecoder() }
}

public extension Config {
    /// A copy limited to what the app's UI manages: the nav shortcut, the
    /// display-cycle toggle + modifier, and the launcher list. Every monitor
    /// sub-binding the UI doesn't surface is cleared, so the running engine
    /// never has "phantom" shortcuts the user can't see or control.
    func curated() -> Config {
        var c = self
        c.features.monitors.optionScroll = false
        c.features.monitors.jumpKeys = []
        c.features.monitors.jumpClickKeys = []
        c.features.monitors.parkKeys = []
        c.features.monitors.focusLeft = KeyBinding()
        c.features.monitors.focusRight = KeyBinding()
        c.features.monitors.nextDisplay = KeyBinding()
        c.features.monitors.prevDisplay = KeyBinding()
        return c
    }

    /// Name of the app launcher already using this key+mods (for conflict prompts), or nil.
    func appLauncherName(forKey key: String, mods: [String], excludingID id: UUID?) -> String? {
        for a in apps where a.id != id {
            if a.key.lowercased() == key.lowercased() && Set(a.mods) == Set(mods) {
                return a.names.first ?? a.bundleID
            }
        }
        return nil
    }
}
