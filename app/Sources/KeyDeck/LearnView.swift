import SwiftUI

/// The Learn tab — discoverability without cluttering Settings.
struct LearnView: View {
    private struct Topic: Identifiable { let id = UUID(); let title: String; let body: String }

    private let topics: [Topic] = [
        .init(title: "What is Navigation Mode?",
              body: "A keyboard layer for controlling your Mac. Press your trigger (default Ctrl+=) to enter it; the pointer and shortcuts come under keyboard control. Press Esc to leave. Launching an app also leaves it automatically."),
        .init(title: "How to switch displays",
              body: "Enter Navigation Mode, then press ⌥1 / ⌥2 / ⌥3 to jump to display 1, 2, or 3. Pro users can add Next/Previous-display shortcuts and Option-tap cycling under Customize."),
        .init(title: "How app launchers work",
              body: "In Navigation Mode, press a launcher key to open that app (e.g. C → ChatGPT). Add launchers in Settings; pick from the apps you have installed — no bundle IDs to type."),
        .init(title: "Moving the pointer",
              body: "In Navigation Mode: h / j / k / l move the pointer left/down/up/right, d / u scroll, and ? shows an on-screen list of every shortcut."),
        .init(title: "Default shortcuts",
              body: "Enter: Ctrl+=   ·   Leave: Esc   ·   Move: h j k l   ·   Scroll: d u   ·   Displays: ⌥1 ⌥2 ⌥3   ·   Help: ?"),
        .init(title: "Troubleshooting",
              body: "If shortcuts don't work, open Settings — if the banner says the engine isn't active, click “Set up engine”. That installs KeyDeck into Hammerspoon (your own config is backed up and kept). Make sure Hammerspoon is running and has Accessibility permission."),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Learn").font(.title2).bold()
                ForEach(topics) { t in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(t.title).font(.headline)
                        Text(t.body).font(.callout).foregroundColor(.secondary).fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(20)
        }
    }
}
