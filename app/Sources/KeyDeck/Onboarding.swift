import SwiftUI
import KeyDeckCore

/// First-run wizard: explains the three concepts and proposes launchers from the
/// apps actually installed, so the user is productive immediately.
struct OnboardingView: View {
    /// Called with the chosen launchers (empty if the user skips).
    var onFinish: ([AppShortcut]) -> Void

    @State private var suggestions: [AppShortcut] = []
    @State private var selected: Set<UUID> = []
    @State private var icons: [String: NSImage] = [:]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Welcome to KeyDeck").font(.largeTitle).bold()

            VStack(alignment: .leading, spacing: 8) {
                concept("1.circle.fill", "Enter Navigation Mode", "Press your trigger key (default: Ctrl+=).")
                concept("2.circle.fill", "Move between displays", "Jump across monitors with a keystroke.")
                concept("3.circle.fill", "Launch apps", "Press a key to open your favorite apps.")
            }
            Text("Press Esc to leave Navigation Mode anytime. Press ? inside it to see every shortcut.")
                .font(.callout).foregroundColor(.secondary)

            Divider()
            Text("We found these apps — pick the launchers you'd like:").font(.headline)

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(suggestions) { app in row(app) }
                }
            }
            .frame(height: 220)
            .background(Color(nsColor: .textBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(nsColor: .separatorColor)))

            HStack {
                Button("Skip") { onFinish([]) }
                Spacer()
                Text("Trigger: Ctrl+=").font(.callout).foregroundColor(.secondary)
                Button("Create Defaults") { onFinish(suggestions.filter { selected.contains($0.id) }) }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 540)
        .onAppear(perform: load)
    }

    private func concept(_ icon: String, _ title: String, _ desc: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon).foregroundColor(.accentColor).font(.title3)
            VStack(alignment: .leading, spacing: 1) {
                Text(title).bold()
                Text(desc).font(.callout).foregroundColor(.secondary)
            }
        }
    }

    private func row(_ app: AppShortcut) -> some View {
        let on = Binding(
            get: { selected.contains(app.id) },
            set: { if $0 { selected.insert(app.id) } else { selected.remove(app.id) } })
        return HStack(spacing: 10) {
            Toggle("", isOn: on).labelsHidden()
            Text(app.key.uppercased()).font(.system(.body, design: .rounded)).bold()
                .frame(width: 24)
                .padding(.vertical, 2).padding(.horizontal, 6)
                .background(Color.accentColor.opacity(0.15)).clipShape(RoundedRectangle(cornerRadius: 5))
            if let icon = icons[app.bundleID] {
                Image(nsImage: icon).resizable().frame(width: 18, height: 18)
            }
            Text(app.names.first ?? app.bundleID)
            Spacer()
        }
        .padding(.horizontal, 10).padding(.vertical, 6)
    }

    private func load() {
        let installed = AppCatalog.installed()
        suggestions = SuggestedLaunchers.suggestions(installed: installed.map { ($0.id, $0.name) })
        selected = Set(suggestions.map { $0.id })
        icons = Dictionary(installed.map { ($0.id, $0.icon) }, uniquingKeysWith: { a, _ in a })
    }
}
