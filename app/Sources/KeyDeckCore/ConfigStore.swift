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
    /// Built-in presets mirroring config/presets/*.json.
    static func preset(named name: String) -> Config {
        switch name {
        case "developer":
            var c = Config.default
            c.preset = "developer"
            c.features.cursor.enabled = true
            c.features.windows.enabled = true
            c.apps = [
                AppShortcut(key: "c", mods: [], bundleID: "com.openai.chat", names: ["ChatGPT"], clickTarget: "bottom"),
                AppShortcut(key: "c", mods: ["shift"], bundleID: "com.anthropic.claudefordesktop", names: ["Claude"], clickTarget: "center"),
                AppShortcut(key: "g", mods: [], bundleID: "com.google.Chrome", names: ["Google Chrome"], clickTarget: "center"),
                AppShortcut(key: "o", mods: [], bundleID: "company.thebrowser.Browser", names: ["Arc"], clickTarget: "center"),
                AppShortcut(key: "t", mods: [], bundleID: "com.microsoft.teams2", names: ["Microsoft Teams"], clickTarget: "center"),
            ]
            return c
        case "minimal":
            var c = Config.default
            c.preset = "minimal"
            c.features.visual.enabled = false
            c.features.cursor.enabled = false
            c.features.windows.enabled = false
            c.features.monitors.jumpClickKeys = []
            c.features.monitors.parkKeys = []
            c.apps = []
            return c
        default:
            var c = Config.default
            c.preset = "default"
            return c
        }
    }

    static let presetNames = ["default", "developer", "minimal"]

    /// A copy limited to what the essentials editor manages. Clears the monitor
    /// sub-bindings and hidden features that the UI doesn't surface, so the running
    /// engine config never has "phantom" shortcuts the user can't see or control.
    func curatedForEssentials() -> Config {
        var c = self
        c.features.cursor.enabled = false
        c.features.windows.enabled = false
        c.features.monitors.optionScroll = false
        c.features.monitors.jumpClickKeys = []
        c.features.monitors.parkKeys = []
        c.features.monitors.focusLeft = KeyBinding()
        c.features.monitors.focusRight = KeyBinding()
        return c
    }
}
