import Foundation

// Decode helper: pull a value if present, otherwise fall back to a default. This
// mirrors the engine's deep-merge-over-defaults behavior, so a partial config
// file (or a preset that only sets a few keys) loads cleanly into a full Config.
extension KeyedDecodingContainer {
    func get<T: Decodable>(_ key: Key, default def: T) -> T {
        // `try?` flattens decodeIfPresent's `T?` to `T?`, so a single binding
        // yields the decoded value; absent/null/mismatched keys fall back to def.
        if let present = try? decodeIfPresent(T.self, forKey: key) {
            return present
        }
        return def
    }
}

/// A key + modifier combination. Named `KeyBinding` (not `Binding`) to avoid
/// colliding with SwiftUI.Binding.
public struct KeyBinding: Codable, Hashable {
    public var mods: [String]
    public var key: String

    public init(mods: [String] = [], key: String = "") {
        self.mods = mods
        self.key = key
    }
}

extension KeyBinding {
    enum CodingKeys: String, CodingKey { case mods, key }
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.mods = c.get(.mods, default: [])
        self.key = c.get(.key, default: "")
    }
}

public struct Tuning: Codable, Equatable {
    public var scrollStep: Double
    public var scrollInitialDelay: Double
    public var scrollRepeatInterval: Double
    public var directionInitialDelay: Double
    public var directionRepeatInterval: Double
    public var dragMoveFrac: Double
    public var globalCursorStep: Double
    public var globalCursorHoldStep: Double
    public var globalCursorRepeatDelay: Double
    public var globalCursorRepeatInterval: Double
    public var optionReleaseIdleSeconds: Double
    public var optionScrollAmount: Double

    public static let `default` = Tuning(
        scrollStep: 62, scrollInitialDelay: 0.15, scrollRepeatInterval: 0.05,
        directionInitialDelay: 0.05, directionRepeatInterval: 0.15, dragMoveFrac: 0.05,
        globalCursorStep: 180, globalCursorHoldStep: 68,
        globalCursorRepeatDelay: 0.05, globalCursorRepeatInterval: 0.02,
        optionReleaseIdleSeconds: 2.0, optionScrollAmount: 260)
}

extension Tuning {
    enum CodingKeys: String, CodingKey {
        case scrollStep, scrollInitialDelay, scrollRepeatInterval, directionInitialDelay
        case directionRepeatInterval, dragMoveFrac, globalCursorStep, globalCursorHoldStep
        case globalCursorRepeatDelay, globalCursorRepeatInterval, optionReleaseIdleSeconds, optionScrollAmount
    }
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = Tuning.default
        scrollStep = c.get(.scrollStep, default: d.scrollStep)
        scrollInitialDelay = c.get(.scrollInitialDelay, default: d.scrollInitialDelay)
        scrollRepeatInterval = c.get(.scrollRepeatInterval, default: d.scrollRepeatInterval)
        directionInitialDelay = c.get(.directionInitialDelay, default: d.directionInitialDelay)
        directionRepeatInterval = c.get(.directionRepeatInterval, default: d.directionRepeatInterval)
        dragMoveFrac = c.get(.dragMoveFrac, default: d.dragMoveFrac)
        globalCursorStep = c.get(.globalCursorStep, default: d.globalCursorStep)
        globalCursorHoldStep = c.get(.globalCursorHoldStep, default: d.globalCursorHoldStep)
        globalCursorRepeatDelay = c.get(.globalCursorRepeatDelay, default: d.globalCursorRepeatDelay)
        globalCursorRepeatInterval = c.get(.globalCursorRepeatInterval, default: d.globalCursorRepeatInterval)
        optionReleaseIdleSeconds = c.get(.optionReleaseIdleSeconds, default: d.optionReleaseIdleSeconds)
        optionScrollAmount = c.get(.optionScrollAmount, default: d.optionScrollAmount)
    }
}

public struct NavFeature: Codable, Equatable {
    public var enabled: Bool
    public var enterKeys: [KeyBinding]
    public var exitKeys: [KeyBinding]
    public static let `default` = NavFeature(
        enabled: true,
        enterKeys: [KeyBinding(mods: ["ctrl", "alt", "cmd"], key: "space"),
                    KeyBinding(mods: [], key: "f12"),
                    KeyBinding(mods: ["ctrl"], key: "=")],
        exitKeys: [KeyBinding(mods: [], key: "escape"),
                   KeyBinding(mods: ["ctrl"], key: "c")])
}
extension NavFeature {
    enum CodingKeys: String, CodingKey { case enabled, enterKeys, exitKeys }
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = NavFeature.default
        enabled = c.get(.enabled, default: d.enabled)
        enterKeys = c.get(.enterKeys, default: d.enterKeys)
        exitKeys = c.get(.exitKeys, default: d.exitKeys)
    }
}

public struct ToggleFeature: Codable, Equatable {
    public var enabled: Bool
    public init(enabled: Bool) { self.enabled = enabled }
}
extension ToggleFeature {
    enum CodingKeys: String, CodingKey { case enabled }
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        enabled = c.get(.enabled, default: true)
    }
}

public struct CursorKeys: Codable, Equatable {
    public var left, down, up, right, click: String
    public static let `default` = CursorKeys(left: "h", down: "j", up: "k", right: "l", click: "i")
}
extension CursorKeys {
    enum CodingKeys: String, CodingKey { case left, down, up, right, click }
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = CursorKeys.default
        left = c.get(.left, default: d.left); down = c.get(.down, default: d.down)
        up = c.get(.up, default: d.up); right = c.get(.right, default: d.right)
        click = c.get(.click, default: d.click)
    }
}

public struct CursorFeature: Codable, Equatable {
    public var enabled: Bool
    public var mods: [String]
    public var keys: CursorKeys
    public static let `default` = CursorFeature(enabled: false, mods: ["alt", "cmd", "shift"], keys: .default)
}
extension CursorFeature {
    enum CodingKeys: String, CodingKey { case enabled, mods, keys }
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = CursorFeature.default
        enabled = c.get(.enabled, default: d.enabled)
        mods = c.get(.mods, default: d.mods)
        keys = c.get(.keys, default: d.keys)
    }
}

public struct MonitorsFeature: Codable, Equatable {
    public var enabled: Bool
    public var skipVirtualDisplayPattern: String
    public var optionTapCycle: Bool
    public var optionScroll: Bool
    public var jumpKeys: [String]
    public var jumpClickKeys: [String]
    public var parkKeys: [String]
    public var parkPadding: Double
    public var focusLeft: KeyBinding
    public var focusRight: KeyBinding
    public static let `default` = MonitorsFeature(
        enabled: true, skipVirtualDisplayPattern: "16:9|HiDPI|Virtual",
        optionTapCycle: true, optionScroll: true,
        jumpKeys: ["1", "2", "3"], jumpClickKeys: ["0", "9", "8"], parkKeys: ["4", "5", "6"],
        parkPadding: 30,
        focusLeft: KeyBinding(mods: ["cmd", "shift"], key: "-"),
        focusRight: KeyBinding(mods: ["cmd", "shift"], key: "="))
}
extension MonitorsFeature {
    enum CodingKeys: String, CodingKey {
        case enabled, skipVirtualDisplayPattern, optionTapCycle, optionScroll
        case jumpKeys, jumpClickKeys, parkKeys, parkPadding, focusLeft, focusRight
    }
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = MonitorsFeature.default
        enabled = c.get(.enabled, default: d.enabled)
        skipVirtualDisplayPattern = c.get(.skipVirtualDisplayPattern, default: d.skipVirtualDisplayPattern)
        optionTapCycle = c.get(.optionTapCycle, default: d.optionTapCycle)
        optionScroll = c.get(.optionScroll, default: d.optionScroll)
        jumpKeys = c.get(.jumpKeys, default: d.jumpKeys)
        jumpClickKeys = c.get(.jumpClickKeys, default: d.jumpClickKeys)
        parkKeys = c.get(.parkKeys, default: d.parkKeys)
        parkPadding = c.get(.parkPadding, default: d.parkPadding)
        focusLeft = c.get(.focusLeft, default: d.focusLeft)
        focusRight = c.get(.focusRight, default: d.focusRight)
    }
}

public struct WindowsFeature: Codable, Equatable {
    public var enabled: Bool
    public var hide: KeyBinding
    public var restore: KeyBinding
    public static let `default` = WindowsFeature(
        enabled: false,
        hide: KeyBinding(mods: ["alt", "cmd"], key: "h"),
        restore: KeyBinding(mods: ["alt", "shift"], key: "r"))
}
extension WindowsFeature {
    enum CodingKeys: String, CodingKey { case enabled, hide, restore }
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = WindowsFeature.default
        enabled = c.get(.enabled, default: d.enabled)
        hide = c.get(.hide, default: d.hide)
        restore = c.get(.restore, default: d.restore)
    }
}

public struct Features: Codable, Equatable {
    public var nav: NavFeature
    public var visual: ToggleFeature
    public var cursor: CursorFeature
    public var monitors: MonitorsFeature
    public var windows: WindowsFeature
    public static let `default` = Features(
        nav: .default, visual: ToggleFeature(enabled: true),
        cursor: .default, monitors: .default, windows: .default)
}
extension Features {
    enum CodingKeys: String, CodingKey { case nav, visual, cursor, monitors, windows }
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = Features.default
        nav = c.get(.nav, default: d.nav)
        visual = c.get(.visual, default: d.visual)
        cursor = c.get(.cursor, default: d.cursor)
        monitors = c.get(.monitors, default: d.monitors)
        windows = c.get(.windows, default: d.windows)
    }
}

public struct AppShortcut: Codable, Identifiable, Hashable {
    public var id: UUID
    public var key: String
    public var mods: [String]
    public var bundleID: String
    public var names: [String]
    public var clickTarget: String   // "center" | "bottom" | "none"
    public var exitNav: Bool

    public init(key: String = "", mods: [String] = [], bundleID: String = "",
                names: [String] = [], clickTarget: String = "center", exitNav: Bool = true) {
        self.id = UUID()
        self.key = key; self.mods = mods; self.bundleID = bundleID
        self.names = names; self.clickTarget = clickTarget; self.exitNav = exitNav
    }

    // `id` is UI-only identity; value equality ignores it so config comparison
    // and round-trip tests behave correctly.
    public static func == (l: AppShortcut, r: AppShortcut) -> Bool {
        l.key == r.key && l.mods == r.mods && l.bundleID == r.bundleID
            && l.names == r.names && l.clickTarget == r.clickTarget && l.exitNav == r.exitNav
    }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(key); hasher.combine(mods); hasher.combine(bundleID)
        hasher.combine(names); hasher.combine(clickTarget); hasher.combine(exitNav)
    }
}
extension AppShortcut {
    // `id` is app-only, never serialized to the config file.
    enum CodingKeys: String, CodingKey { case key, mods, bundleID, names, clickTarget, exitNav }
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        key = c.get(.key, default: "")
        mods = c.get(.mods, default: [])
        bundleID = c.get(.bundleID, default: "")
        names = c.get(.names, default: [])
        clickTarget = c.get(.clickTarget, default: "center")
        exitNav = c.get(.exitNav, default: true)
    }
    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(key, forKey: .key)
        try c.encode(mods, forKey: .mods)
        try c.encode(bundleID, forKey: .bundleID)
        try c.encode(names, forKey: .names)
        try c.encode(clickTarget, forKey: .clickTarget)
        try c.encode(exitNav, forKey: .exitNav)
    }
}

public struct Config: Codable, Equatable {
    public var preset: String
    public var tuning: Tuning
    public var features: Features
    public var apps: [AppShortcut]

    public static let `default` = Config(
        preset: "default", tuning: .default, features: .default,
        apps: [
            AppShortcut(key: "c", mods: [], bundleID: "com.openai.chat", names: ["ChatGPT"], clickTarget: "bottom", exitNav: true),
            AppShortcut(key: "c", mods: ["shift"], bundleID: "com.microsoft.VSCode", names: ["Visual Studio Code", "Code"], clickTarget: "center", exitNav: true),
            AppShortcut(key: "o", mods: [], bundleID: "company.thebrowser.Browser", names: ["Arc"], clickTarget: "center", exitNav: true),
            AppShortcut(key: "o", mods: ["shift"], bundleID: "com.chatgpt.atlas", names: ["ChatGPT Atlas"], clickTarget: "center", exitNav: true),
            AppShortcut(key: "t", mods: [], bundleID: "com.microsoft.teams2", names: ["Microsoft Teams"], clickTarget: "center", exitNav: true),
        ])
}
extension Config {
    enum CodingKeys: String, CodingKey { case preset, tuning, features, apps }
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = Config.default
        preset = c.get(.preset, default: d.preset)
        tuning = c.get(.tuning, default: d.tuning)
        features = c.get(.features, default: d.features)
        apps = c.get(.apps, default: d.apps)
    }
}
