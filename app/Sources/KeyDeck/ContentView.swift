import SwiftUI
import KeyDeckCore

struct ContentView: View {
    @State private var config = ConfigStore.load()
    @State private var status = ""
    @State private var statusIsError = false
    @State private var appsByID: [String: InstalledApp] = [:]
    @State private var showAdd = false
    @State private var editingIndex: Int?
    @State private var showAdvanced = false
    @State private var showOnboarding = !ConfigStore.fileExists
    @State private var showLicense = false
    @State private var capsEnabled = CapsLockSetup.isEnabled
    @StateObject private var license = LicenseManager()

    private var conflicts: [BindingConflict] { Validation.conflicts(in: config) }
    private var canApply: Bool { conflicts.isEmpty && license.isApplyAllowed }

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
                    advancedSection
                }
                .padding(20)
            }
            Divider()
            footer
        }
        .onAppear {
            appsByID = Dictionary(AppCatalog.installed().map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        }
        .task { await license.revalidateIfStale() }
        .sheet(isPresented: $showOnboarding) {
            OnboardingView { chosen in
                if !chosen.isEmpty { config.apps = chosen }
                try? ConfigStore.save(config.curatedForEssentials())
                showOnboarding = false
            }
        }
        .sheet(isPresented: $showAdd) {
            AddAppSheet(
                conflictName: { key, mods in config.appLauncherName(forKey: key, mods: mods, excludingID: nil) },
                onAdd: { shortcut in
                    config.apps.removeAll { $0.key.lowercased() == shortcut.key.lowercased() && Set($0.mods) == Set(shortcut.mods) }
                    config.apps.append(shortcut)
                })
        }
        .sheet(isPresented: Binding(get: { editingIndex != nil }, set: { if !$0 { editingIndex = nil } })) {
            if let i = editingIndex, config.apps.indices.contains(i) {
                AppEditorSheet(app: $config.apps[i],
                               conflictName: { key, mods in
                                   config.appLauncherName(forKey: key, mods: mods, excludingID: config.apps[i].id)
                               })
            }
        }
        .sheet(isPresented: $showLicense) { LicenseSheet(license: license) }
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("KeyDeck").font(.title2).bold()
            Text("Press a trigger key to enter Navigation Mode. While active, use keyboard shortcuts to switch displays and launch apps. Press Esc to leave.")
                .font(.callout).foregroundColor(.secondary).fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20).padding(.vertical, 14)
    }

    // MARK: Navigation Mode

    private var navSection: some View {
        SectionCard(title: "Navigation Mode", isOn: $config.features.nav.enabled) {
            HStack {
                Text("Trigger").frame(width: 80, alignment: .leading)
                Picker("", selection: triggerPreset) {
                    ForEach(TriggerPreset.allCases) { Text($0.label).tag($0) }
                }.labelsHidden().frame(width: 250)
            }
            let kind = config.features.nav.activator.kind
            if kind == "tapModifier" {
                Toggle("Activate on release (ignored when used in a shortcut)",
                       isOn: $config.features.nav.activator.onRelease)
            }
            if triggerPreset.wrappedValue == .custom || kind == "hyper" {
                HStack {
                    Text("Shortcut").frame(width: 80, alignment: .leading)
                    ShortcutRecorder(binding: $config.features.nav.activator.hotkey).frame(width: 130, height: 26)
                }
            }
            if kind == "capsLock" { capsLockRow }
            Text(triggerPreset.wrappedValue.explanation(config.features.nav.activator))
                .font(.callout).foregroundColor(.secondary).fixedSize(horizontal: false, vertical: true)
            Text("In Navigation Mode: h / j / k / l move the pointer, d / u scroll, your app keys launch apps. Press ? for help, Esc to leave.")
                .font(.caption).foregroundColor(.secondary).fixedSize(horizontal: false, vertical: true)
        }
    }

    private var capsLockRow: some View {
        HStack(spacing: 10) {
            Text("Caps Lock").frame(width: 80, alignment: .leading)
            if capsEnabled {
                Label("Set up", systemImage: "checkmark.circle.fill").foregroundColor(.green)
                Button("Remove") { CapsLockSetup.disable(); capsEnabled = false }
            } else {
                Button("Set up Caps Lock") { capsEnabled = CapsLockSetup.enable() }
                Text("Remaps Caps Lock → F18 (reversible).").font(.caption).foregroundColor(.secondary)
            }
            Spacer()
        }
    }

    // MARK: Display Switching

    private var displaySection: some View {
        SectionCard(title: "Display Switching", isOn: $config.features.monitors.enabled) {
            HStack {
                Text("Next display").frame(width: 130, alignment: .leading)
                ShortcutRecorder(binding: $config.features.monitors.nextDisplay).frame(width: 120, height: 26)
            }
            HStack {
                Text("Previous display").frame(width: 130, alignment: .leading)
                ShortcutRecorder(binding: $config.features.monitors.prevDisplay).frame(width: 120, height: 26)
            }
            Toggle("Jump to a display with ⌥1 / ⌥2 / ⌥3", isOn: jumpEnabled)
            Toggle("Also tap ⌥ to cycle displays", isOn: $config.features.monitors.optionTapCycle)
            if config.features.monitors.optionTapCycle && config.features.nav.activator.modifier.contains("Alt") {
                Text("⚠ This may clash with an Option-based Nav Mode trigger.")
                    .font(.caption).foregroundColor(.orange)
            }
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
        HStack(spacing: 10) {
            Text(app.key.isEmpty ? "—" : Validation.display(mods: app.mods, key: app.key))
                .font(.system(.body, design: .rounded)).bold().frame(minWidth: 34)
                .padding(.vertical, 3).padding(.horizontal, 6)
                .background(Color.accentColor.opacity(0.15)).clipShape(RoundedRectangle(cornerRadius: 5))
            Text("→").foregroundColor(.secondary)
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

    // MARK: Advanced

    private var advancedSection: some View {
        DisclosureGroup("Advanced", isExpanded: $showAdvanced) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Navigation").font(.caption).foregroundColor(.secondary)
                Toggle("Visual selection mode", isOn: $config.features.visual.enabled)
                Toggle("Global cursor movement (⌥⌘⇧ + h/j/k/l)", isOn: $config.features.cursor.enabled)
                Divider()
                Text("Developer").font(.caption).foregroundColor(.secondary)
                Toggle("Debug logging", isOn: $config.debug)
                HStack(spacing: 12) {
                    Button("Reveal config file") {
                        NSWorkspace.shared.selectFile(ConfigStore.path, inFileViewerRootedAtPath: "")
                    }
                    Button("License…") { showLicense = true }
                    Button("Reset to defaults") { config = .default }
                }
            }
            .padding(.top, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: Footer

    private var footer: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(license.statusText()).font(.caption)
                    .foregroundColor(license.isApplyAllowed ? .secondary : .red)
                Button { NSWorkspace.shared.open(URL(string: "https://github.com/arturgrochau")!) } label: {
                    Text("Made by Artur Grochau").font(.caption2)
                }.buttonStyle(.link)
            }
            Spacer()
            if !status.isEmpty {
                Text(status).font(.caption).foregroundColor(statusIsError ? .red : .secondary)
                    .lineLimit(1).truncationMode(.middle)
            }
            if !license.isApplyAllowed { Button("Enter License") { showLicense = true } }
            Button { apply() } label: { Text("Apply & Reload").bold() }
                .keyboardShortcut("s", modifiers: .command)
                .disabled(!canApply)
                .help(license.isApplyAllowed ? "" : "Trial expired — enter a license to Apply")
        }
        .padding(.horizontal, 20).padding(.vertical, 12)
    }

    private func apply() {
        guard canApply else { return }
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

    // MARK: Bindings

    private var triggerPreset: Binding<TriggerPreset> {
        Binding(get: { TriggerPreset.from(config.features.nav.activator) },
                set: { config.features.nav.activator = $0.activator(existing: config.features.nav.activator) })
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
            Toggle(isOn: $isOn) { Text(title).font(.headline) }.toggleStyle(.switch)
            if isOn {
                VStack(alignment: .leading, spacing: 8) { content() }.padding(.leading, 4)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(nsColor: .separatorColor).opacity(0.5)))
    }
}
