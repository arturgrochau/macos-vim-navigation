import Foundation

/// A category of app with a suggested NAV-MODE key. Matching is by bundle ID
/// (exact) or a keyword in the app's display name. Used by the first-run wizard
/// to propose sensible launchers from whatever the user actually has installed.
public struct LauncherCategory {
    public let key: String
    public let label: String
    public let bundleIDs: [String]
    public let nameKeywords: [String]
    public let clickTarget: String
}

public enum SuggestedLaunchers {
    /// Unique-key catalog tuned for a broad range of Mac professionals.
    public static let catalog: [LauncherCategory] = [
        .init(key: "b", label: "Browser",
              bundleIDs: ["company.thebrowser.Browser", "com.google.Chrome", "com.apple.Safari",
                          "com.microsoft.edgemac", "com.brave.Browser", "org.mozilla.firefox", "com.chatgpt.atlas"],
              nameKeywords: ["arc", "chrome", "safari", "edge", "brave", "firefox"], clickTarget: "center"),
        .init(key: "c", label: "ChatGPT", bundleIDs: ["com.openai.chat"], nameKeywords: ["chatgpt"], clickTarget: "bottom"),
        .init(key: "a", label: "Claude", bundleIDs: ["com.anthropic.claudefordesktop"], nameKeywords: ["claude"], clickTarget: "bottom"),
        .init(key: "e", label: "Code editor",
              bundleIDs: ["com.microsoft.VSCode", "com.todesktop.230313mzl4w4u92", "com.apple.dt.Xcode", "dev.zed.Zed"],
              nameKeywords: ["visual studio code", "code", "cursor", "xcode", "zed"], clickTarget: "center"),
        .init(key: "t", label: "Terminal",
              bundleIDs: ["com.apple.Terminal", "com.googlecode.iterm2", "dev.warp.Warp-Stable", "com.mitchellh.ghostty"],
              nameKeywords: ["terminal", "iterm", "warp", "ghostty"], clickTarget: "center"),
        .init(key: "s", label: "Slack", bundleIDs: ["com.tinyspeck.slackmacgap"], nameKeywords: ["slack"], clickTarget: "center"),
        .init(key: "m", label: "Mail / Messages",
              bundleIDs: ["com.apple.mail", "com.apple.MobileSMS"], nameKeywords: ["mail", "messages"], clickTarget: "center"),
        .init(key: "n", label: "Notes / Notion",
              bundleIDs: ["com.apple.Notes", "notion.id"], nameKeywords: ["notes", "notion", "obsidian"], clickTarget: "center"),
        .init(key: "f", label: "Finder", bundleIDs: ["com.apple.finder"], nameKeywords: ["finder"], clickTarget: "center"),
    ]

    /// Given the installed apps (bundleID + display name), return one launcher per
    /// category that has a match, using the first matching installed app.
    public static func suggestions(installed: [(bundleID: String, name: String)]) -> [AppShortcut] {
        var out: [AppShortcut] = []
        for cat in catalog {
            let match = installed.first { app in
                cat.bundleIDs.contains(app.bundleID)
                    || cat.nameKeywords.contains { app.name.lowercased().contains($0) }
            }
            if let m = match {
                out.append(AppShortcut(key: cat.key, mods: [], bundleID: m.bundleID,
                                       names: [m.name], clickTarget: cat.clickTarget, exitNav: true))
            }
        }
        return out
    }
}
