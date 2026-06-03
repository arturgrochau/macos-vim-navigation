import KeyDeckCore

/// User-facing Nav Mode trigger choices, mapped to engine `NavActivator` configs.
enum TriggerPreset: String, CaseIterable, Identifiable {
    case tapRightOption, doubleTapOption, capsLock, controlEquals, hyper, custom
    var id: String { rawValue }

    var label: String {
        switch self {
        case .controlEquals:   return "Ctrl + =  (recommended)"
        case .doubleTapOption: return "Double-tap Option"
        case .tapRightOption:  return "Right Option (on release)"
        case .capsLock:        return "Caps Lock"
        case .hyper:           return "Hyper key (⌃⌥⇧⌘ + key)"
        case .custom:          return "Custom…"
        }
    }

    /// Display order in the Change sheet (recommended first).
    static var ordered: [TriggerPreset] { [.controlEquals, .doubleTapOption, .tapRightOption, .capsLock, .hyper, .custom] }

    /// Build the activator for this preset, preserving the user's hotkey where useful.
    func activator(existing: NavActivator) -> NavActivator {
        switch self {
        case .tapRightOption:
            return NavActivator(kind: "tapModifier", modifier: "rightAlt", onRelease: existing.onRelease, hotkey: existing.hotkey)
        case .doubleTapOption:
            return NavActivator(kind: "doubleTapModifier", modifier: "alt", onRelease: existing.onRelease, hotkey: existing.hotkey)
        case .capsLock:
            return NavActivator(kind: "capsLock", modifier: existing.modifier, onRelease: existing.onRelease,
                                hotkey: KeyBinding(mods: [], key: "f18"))
        case .controlEquals:
            return NavActivator(kind: "hotkey", modifier: existing.modifier, onRelease: existing.onRelease,
                                hotkey: KeyBinding(mods: ["ctrl"], key: "="))
        case .hyper:
            let key = existing.hotkey.key.isEmpty ? "space" : existing.hotkey.key
            return NavActivator(kind: "hyper", modifier: existing.modifier, onRelease: existing.onRelease,
                                hotkey: KeyBinding(mods: ["ctrl", "alt", "shift", "cmd"], key: key))
        case .custom:
            let hk = existing.hotkey.key.isEmpty ? KeyBinding(mods: ["ctrl", "alt"], key: "n") : existing.hotkey
            return NavActivator(kind: "hotkey", modifier: existing.modifier, onRelease: existing.onRelease, hotkey: hk)
        }
    }

    static func from(_ a: NavActivator) -> TriggerPreset {
        switch a.kind {
        case "tapModifier":       return a.modifier == "rightAlt" ? .tapRightOption : .custom
        case "doubleTapModifier": return .doubleTapOption
        case "capsLock":          return .capsLock
        case "hyper":             return .hyper
        case "hotkey":            return (a.hotkey.mods == ["ctrl"] && a.hotkey.key == "=") ? .controlEquals : .custom
        default:                  return .custom
        }
    }

    func explanation(_ a: NavActivator) -> String {
        switch self {
        case .tapRightOption:
            return "Tap the right ⌥ key by itself to toggle Navigation Mode. Using ⌥ in a shortcut still works normally."
        case .doubleTapOption: return "Quickly tap ⌥ twice to toggle Navigation Mode."
        case .capsLock:        return "Press Caps Lock to toggle Navigation Mode (set up below)."
        case .controlEquals:   return "Press Control + = to toggle Navigation Mode."
        case .hyper:           return "Press your Hyper key combo to toggle Navigation Mode."
        case .custom:
            return a.hotkey.key.isEmpty ? "Record a shortcut to toggle Navigation Mode."
                : "Press \(Validation.display(mods: a.hotkey.mods, key: a.hotkey.key)) to toggle Navigation Mode."
        }
    }
}
