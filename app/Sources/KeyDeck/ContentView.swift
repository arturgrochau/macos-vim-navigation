import SwiftUI
import KeyDeckCore

struct ContentView: View {
    @State private var config = ConfigStore.load()
    @State private var status = ConfigStore.fileExists ? "Loaded your settings." : "Using defaults — Apply to save."
    @State private var statusIsError = false
    @State private var appsByID: [String: InstalledApp] = [:]
    @State private var showAdd = false
    @State private var editingIndex: Int?

    private var conflicts: [BindingConflict] { Validation.conflicts(in: config) }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if !conflicts.isEmpty { conflictBanner }
                    navSection
                    displaySection
                    appsSection
                }
                .padding(20)
            }
            Divider()
            footer
        }
        .onAppear {
            appsByID = Dictionary(AppCatalog.installed().map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        }
        .sheet(isPresented: $showAdd) {
            AddAppSheet { config.apps.append($0) }
        }
        .sheet(isPresented: Binding(get: { editingIndex != nil }, set: { if !$0 { editingIndex = nil } })) {
            if let i = editingIndex, config.apps.indices.contains(i) {
                AppEditorSheet(app: $config.apps[i])
            }
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("KeyDeck").font(.title2).bold()
            Text("Tap a key to enter Navigation Mode, then use your keyboard to move between displays and launch apps. Launching an app returns you to normal typing.")
                .font(.callout).foregroundColor(.secondary).fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20).padding(.vertical, 14)
    }

    // MARK: Navigation Mode

    private var navSection: some View {
        SectionCard(title: "Navigation Mode", isOn: $config.features.nav.enabled) {
            HStack {
                Text("Enter with").frame(width: 90, alignment: .leading)
                Picker("", selection: activationKind) {
                    Text("Right ⌘").tag("rightCmd")
                    Text("Right ⌥").tag("rightAlt")
                    Text("F12").tag("f12")
                    Text("Custom…").tag("custom")
                }.labelsHidden().frame(width: 160)
                if activationKind.wrappedValue == "custom" {
                    ShortcutRecorder(binding: $config.features.nav.activator.hotkey).frame(width: 120, height: 26)
                }
                Spacer()
            }
            Text(activationDescription).font(.callout).foregroundColor(.secondary)
            Text("In Navigation Mode: h / j / k / l move the pointer, d / u scroll, and your app keys (below) launch apps. Press Esc to leave.")
                .font(.caption).foregroundColor(.secondary).fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: Display Switching

    private var displaySection: some View {
        SectionCard(title: "Display Switching", isOn: $config.features.monitors.enabled) {
            Toggle("Tap ⌥ to jump to the next display", isOn: $config.features.monitors.optionTapCycle)
            HStack {
                Text("Next display").frame(width: 130, alignment: .leading)
                ShortcutRecorder(binding: $config.features.monitors.nextDisplay).frame(width: 120, height: 26)
            }
            HStack {
                Text("Previous display").frame(width: 130, alignment: .leading)
                ShortcutRecorder(binding: $config.features.monitors.prevDisplay).frame(width: 120, height: 26)
            }
            Toggle("Jump to a display with ⌥1 / ⌥2 / ⌥3", isOn: jumpEnabled)
        }
    }

    // MARK: App Launchers

    private var appsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("App Launchers").font(.headline)
                Spacer()
                Button { showAdd = true } label: { Label("Add App", systemImage: "plus") }
            }
            Text("While in Navigation Mode, press a key to launch an app.")
                .font(.caption).foregroundColor(.secondary)

            if config.apps.isEmpty {
                Text("No launchers yet. Click “Add App”.").foregroundColor(.secondary).font(.callout).padding(.vertical, 6)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(config.apps.enumerated()), id: \.element.id) { idx, app in
                        appRow(app, index: idx)
                        if idx < config.apps.count - 1 { Divider() }
                    }
                }
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(nsColor: .separatorColor)))
            }
        }
    }

    private func appRow(_ app: AppShortcut, index: Int) -> some View {
        HStack(spacing: 12) {
            keyChip(app)
            if let a = appsByID[app.bundleID] {
                Image(nsImage: a.icon).resizable().frame(width: 20, height: 20)
            } else {
                Image(systemName: "app.dashed").frame(width: 20, height: 20).foregroundColor(.secondary)
            }
            Text(app.names.first ?? app.bundleID)
            Spacer()
            Button { editingIndex = index } label: { Image(systemName: "pencil") }.buttonStyle(.borderless)
            Button(role: .destructive) { config.apps.removeAll { $0.id == app.id } } label: {
                Image(systemName: "trash")
            }.buttonStyle(.borderless)
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
    }

    private func keyChip(_ app: AppShortcut) -> some View {
        Text(app.key.isEmpty ? "—" : Validation.display(mods: app.mods, key: app.key))
            .font(.system(.body, design: .rounded)).bold()
            .frame(minWidth: 34)
            .padding(.vertical, 3).padding(.horizontal, 6)
            .background(Color.accentColor.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 5))
    }

    // MARK: Footer

    private var footer: some View {
        HStack {
            Text(status).font(.callout).foregroundColor(statusIsError ? .red : .secondary)
                .lineLimit(1).truncationMode(.middle)
            Spacer()
            Button("Reset to defaults") { config = .default }
            Button("Reveal config") {
                NSWorkspace.shared.selectFile(ConfigStore.path, inFileViewerRootedAtPath: "")
            }
            Button { apply() } label: { Text("Apply & Reload").bold() }
                .keyboardShortcut("s", modifiers: .command)
                .disabled(!conflicts.isEmpty)
        }
        .padding(.horizontal, 20).padding(.vertical, 12)
    }

    private func apply() {
        do {
            let curated = config.curatedForEssentials()
            try ConfigStore.apply(curated)
            config = curated
            status = "Applied & reloaded."
            statusIsError = false
        } catch {
            status = "Failed: \(error.localizedDescription)"
            statusIsError = true
        }
    }

    // MARK: Conflict banner

    private var conflictBanner: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("Two shortcuts use the same key", systemImage: "exclamationmark.triangle.fill")
                .foregroundColor(.orange).bold()
            ForEach(conflicts, id: \.signature) { c in
                Text("• \(c.signature) is used by \(c.count) shortcuts").font(.callout).foregroundColor(.secondary)
            }
        }
        .padding(12).frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.12)).cornerRadius(8)
    }

    // MARK: Activation helpers

    private var activationKind: Binding<String> {
        Binding(
            get: {
                let a = config.features.nav.activator
                if a.kind == "rightCmd" { return "rightCmd" }
                if a.kind == "rightAlt" { return "rightAlt" }
                if a.hotkey.mods.isEmpty && a.hotkey.key == "f12" { return "f12" }
                return "custom"
            },
            set: { sel in
                let cur = config.features.nav.activator.hotkey
                switch sel {
                case "rightCmd": config.features.nav.activator = NavActivator(kind: "rightCmd", hotkey: cur)
                case "rightAlt": config.features.nav.activator = NavActivator(kind: "rightAlt", hotkey: cur)
                case "f12": config.features.nav.activator = NavActivator(kind: "hotkey", hotkey: KeyBinding(mods: [], key: "f12"))
                default:
                    var hk = cur
                    if hk.key.isEmpty || (hk.mods.isEmpty && hk.key == "f12") { hk = KeyBinding(mods: ["ctrl", "alt"], key: "n") }
                    config.features.nav.activator = NavActivator(kind: "hotkey", hotkey: hk)
                }
            })
    }

    private var activationDescription: String {
        switch activationKind.wrappedValue {
        case "rightCmd": return "Tap the right ⌘ key to toggle Navigation Mode (tapping it alone — it still works as ⌘ in shortcuts)."
        case "rightAlt": return "Tap the right ⌥ key to toggle Navigation Mode."
        case "f12": return "Press F12 to toggle Navigation Mode."
        default:
            let hk = config.features.nav.activator.hotkey
            return hk.key.isEmpty ? "Click the field to record a shortcut."
                : "Press \(Validation.display(mods: hk.mods, key: hk.key)) to toggle Navigation Mode."
        }
    }

    private var jumpEnabled: Binding<Bool> {
        Binding(get: { !config.features.monitors.jumpKeys.isEmpty },
                set: { config.features.monitors.jumpKeys = $0 ? ["1", "2", "3"] : [] })
    }
}

/// A titled card with an enable toggle; its content shows only when enabled.
struct SectionCard<Content: View>: View {
    let title: String
    @Binding var isOn: Bool
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle(isOn: $isOn) { Text(title).font(.headline) }
                .toggleStyle(.switch)
            if isOn {
                VStack(alignment: .leading, spacing: 8) { content() }
                    .padding(.leading, 4)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(nsColor: .separatorColor).opacity(0.5)))
    }
}
