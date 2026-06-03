import SwiftUI
import KeyDeckCore

struct ContentView: View {
    @State private var config: Config = ConfigStore.load()
    @State private var selectedPreset: String = ConfigStore.load().preset
    @State private var status: String = ConfigStore.fileExists ? "Loaded \(ConfigStore.path)" : "No config yet — using defaults"
    @State private var statusIsError = false

    private var conflicts: [BindingConflict] { Validation.conflicts(in: config) }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if !conflicts.isEmpty { conflictBanner }
                    featuresSection
                    appsSection
                }
                .padding(18)
            }
            Divider()
            footer
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 12) {
            Text("KeyDeck").font(.title2).bold()
            Spacer()
            Picker("Preset", selection: $selectedPreset) {
                ForEach(Config.presetNames, id: \.self) { Text($0.capitalized).tag($0) }
            }
            .frame(width: 200)
            .onChange(of: selectedPreset) { new in
                config = Config.preset(named: new)
            }
        }
        .padding(.horizontal, 18).padding(.vertical, 12)
    }

    // MARK: Conflicts

    private var conflictBanner: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("Conflicting shortcuts", systemImage: "exclamationmark.triangle.fill")
                .foregroundColor(.orange).bold()
            ForEach(conflicts, id: \.signature) { c in
                Text("• \(c.signature) is bound \(c.count)× in \(c.scope)")
                    .font(.callout).foregroundColor(.secondary)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.12))
        .cornerRadius(8)
    }

    // MARK: Features

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Features")

            Toggle("NAV MODE (modal vim navigation)", isOn: $config.features.nav.enabled)
            Toggle("Visual selection mode", isOn: $config.features.visual.enabled)

            Toggle("Global cursor movement (outside NAV MODE)", isOn: $config.features.cursor.enabled)
            if config.features.cursor.enabled {
                ModifiersView(mods: $config.features.cursor.mods)
                    .padding(.leading, 22)
            }

            Toggle("Multi-monitor switching", isOn: $config.features.monitors.enabled)
            if config.features.monitors.enabled {
                VStack(alignment: .leading, spacing: 6) {
                    Toggle("⌥ tap → cycle to next physical screen", isOn: $config.features.monitors.optionTapCycle)
                    Toggle("⌥D / ⌥U → scroll half-page globally", isOn: $config.features.monitors.optionScroll)
                    BindingRow(label: "Focus left screen", binding: $config.features.monitors.focusLeft)
                    BindingRow(label: "Focus right screen", binding: $config.features.monitors.focusRight)
                }
                .padding(.leading, 22)
            }

            Toggle("Hide / restore windows", isOn: $config.features.windows.enabled)
            if config.features.windows.enabled {
                VStack(alignment: .leading, spacing: 6) {
                    BindingRow(label: "Hide frontmost app", binding: $config.features.windows.hide)
                    BindingRow(label: "Restore all windows", binding: $config.features.windows.restore)
                }
                .padding(.leading, 22)
            }
        }
    }

    // MARK: Apps

    private var appsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                sectionTitle("App shortcuts (NAV MODE)")
                Spacer()
                Button {
                    config.apps.append(AppShortcut())
                } label: { Label("Add", systemImage: "plus") }
            }
            ForEach($config.apps) { $app in
                AppRow(app: $app) { config.apps.removeAll { $0.id == app.id } }
                Divider()
            }
            if config.apps.isEmpty {
                Text("No app shortcuts.").foregroundColor(.secondary).font(.callout)
            }
        }
    }

    // MARK: Footer

    private var footer: some View {
        HStack {
            Text(status)
                .font(.callout)
                .foregroundColor(statusIsError ? .red : .secondary)
                .lineLimit(1).truncationMode(.middle)
            Spacer()
            Button("Reveal config") {
                NSWorkspace.shared.selectFile(ConfigStore.path, inFileViewerRootedAtPath: "")
            }
            Button {
                apply()
            } label: {
                Text("Apply & Reload").bold()
            }
            .keyboardShortcut("s", modifiers: .command)
            .disabled(!conflicts.isEmpty)
        }
        .padding(.horizontal, 18).padding(.vertical, 12)
    }

    private func apply() {
        do {
            try ConfigStore.apply(config)
            status = "Applied & reloaded → \(ConfigStore.path)"
            statusIsError = false
        } catch {
            status = "Failed: \(error.localizedDescription)"
            statusIsError = true
        }
    }

    private func sectionTitle(_ t: String) -> some View {
        Text(t).font(.headline)
    }
}

// MARK: - Reusable rows

/// Four modifier checkboxes bound to a [String] of Hammerspoon modifier names.
struct ModifiersView: View {
    @Binding var mods: [String]
    private let all: [(name: String, symbol: String)] =
        [("ctrl", "⌃"), ("alt", "⌥"), ("shift", "⇧"), ("cmd", "⌘")]

    var body: some View {
        HStack(spacing: 10) {
            ForEach(all, id: \.name) { m in
                Toggle(m.symbol, isOn: binding(for: m.name))
                    .toggleStyle(.checkbox)
            }
        }
    }

    private func binding(for mod: String) -> Binding<Bool> {
        Binding(
            get: { mods.contains(mod) },
            set: { on in
                if on { if !mods.contains(mod) { mods.append(mod) } }
                else { mods.removeAll { $0 == mod } }
            })
    }
}

/// A label + key field + modifier checkboxes for a single KeyBinding.
struct BindingRow: View {
    let label: String
    @Binding var binding: KeyBinding

    var body: some View {
        HStack(spacing: 10) {
            Text(label).frame(width: 150, alignment: .leading)
            TextField("key", text: $binding.key).frame(width: 70)
            ModifiersView(mods: $binding.mods)
            Spacer()
        }
    }
}

/// One editable app-shortcut row.
struct AppRow: View {
    @Binding var app: AppShortcut
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 10) {
                TextField("key", text: $app.key).frame(width: 50)
                ModifiersView(mods: $app.mods)
                Picker("", selection: $app.clickTarget) {
                    Text("center").tag("center")
                    Text("bottom").tag("bottom")
                    Text("none").tag("none")
                }.frame(width: 110).labelsHidden()
                Toggle("exit NAV", isOn: $app.exitNav)
                Spacer()
                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash")
                }.buttonStyle(.borderless)
            }
            HStack(spacing: 10) {
                TextField("bundle ID (e.g. com.openai.chat)", text: $app.bundleID)
                TextField("display names (comma-separated)", text: namesText)
            }
        }
        .padding(.vertical, 2)
    }

    private var namesText: Binding<String> {
        Binding(
            get: { app.names.joined(separator: ", ") },
            set: { app.names = $0.split(separator: ",").map {
                $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty } })
    }
}
