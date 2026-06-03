import SwiftUI
import KeyDeckCore

/// The Settings tab: the three outcomes (enter Nav Mode, switch displays, launch apps),
/// an engine-health banner, and a verified Apply.
struct SettingsView: View {
    @ObservedObject var model: AppModel
    @Binding var showLicense: Bool

    @State private var appsByID: [String: InstalledApp] = [:]
    @State private var showAdd = false
    @State private var editingIndex: Int?
    @State private var showTriggerChange = false
    @State private var showCustomize = false
    @State private var showUpgrade = false

    private var conflicts: [BindingConflict] { Validation.conflicts(in: model.config) }
    private var canAddLauncher: Bool {
        Entitlements.canAddLauncher(currentCount: model.config.apps.count, isPro: model.isPro)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    EngineBanner(model: model)
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
            AddAppSheet(
                conflictName: { key, mods in model.config.appLauncherName(forKey: key, mods: mods, excludingID: nil) },
                onAdd: { s in
                    model.config.apps.removeAll { $0.key.lowercased() == s.key.lowercased() && Set($0.mods) == Set(s.mods) }
                    model.config.apps.append(s)
                })
        }
        .sheet(isPresented: Binding(get: { editingIndex != nil }, set: { if !$0 { editingIndex = nil } })) {
            if let i = editingIndex, model.config.apps.indices.contains(i) {
                AppEditorSheet(app: $model.config.apps[i],
                               conflictName: { key, mods in
                                   model.config.appLauncherName(forKey: key, mods: mods, excludingID: model.config.apps[i].id)
                               })
            }
        }
        .sheet(isPresented: $showTriggerChange) { TriggerChangeSheet(activator: $model.config.features.nav.activator) }
        .sheet(isPresented: $showCustomize) { DisplayCustomizeSheet(monitors: $model.config.features.monitors) }
        .alert("Upgrade to Pro", isPresented: $showUpgrade) {
            Button("Upgrade…") { showLicense = true }
            Button("Not now", role: .cancel) {}
        } message: {
            Text("The free plan includes up to \(Entitlements.freeMaxLaunchers) app launchers and the three display jumps. Upgrade for unlimited mappings and display customization.")
        }
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
        SectionCard(title: "Navigation Mode", isOn: $model.config.features.nav.enabled) {
            HStack(spacing: 12) {
                Text("Trigger:").foregroundColor(.secondary)
                Text(triggerLabel(model.config.features.nav.activator))
                    .font(.system(.body, design: .rounded)).bold()
                Button("Change") { showTriggerChange = true }
                Spacer()
            }
            Text(triggerSentence(model.config.features.nav.activator))
                .font(.callout).foregroundColor(.secondary).fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: Display Switching

    private var displaySection: some View {
        SectionCard(title: "Display Switching", isOn: $model.config.features.monitors.enabled) {
            Text("In Navigation Mode:").font(.callout).foregroundColor(.secondary)
            HStack(spacing: 18) {
                ForEach(Array(model.config.features.monitors.jumpKeys.prefix(3).enumerated()), id: \.offset) { i, k in
                    Text("⌥\(k) → Display \(i + 1)").font(.system(.body, design: .rounded))
                }
            }
            Button("Customize") { if model.isPro { showCustomize = true } else { showUpgrade = true } }
        }
    }

    // MARK: App Launchers

    private var appsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("App Launchers").font(.headline)
                Spacer()
                Button { if canAddLauncher { showAdd = true } else { showUpgrade = true } } label: {
                    Label("Add", systemImage: "plus")
                }
            }
            if model.config.apps.isEmpty {
                Text("No launchers yet. Click “Add”.").foregroundColor(.secondary).font(.callout).padding(.vertical, 6)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(model.config.apps.enumerated()), id: \.element.id) { idx, app in
                        appRow(app, index: idx)
                        if idx < model.config.apps.count - 1 { Divider() }
                    }
                }
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(nsColor: .separatorColor)))
            }
            if !model.isPro {
                Text("Free plan: \(model.config.apps.count)/\(Entitlements.freeMaxLaunchers) launchers")
                    .font(.caption).foregroundColor(.secondary)
            }
        }
    }

    private func appRow(_ app: AppShortcut, index: Int) -> some View {
        HStack(spacing: 10) {
            Text(app.key.isEmpty ? "—" : Validation.display(mods: app.mods, key: app.key))
                .font(.system(.body, design: .rounded)).bold().frame(minWidth: 30)
            Text("→").foregroundColor(.secondary)
            if let a = appsByID[app.bundleID] {
                Image(nsImage: a.icon).resizable().frame(width: 20, height: 20)
            } else {
                Image(systemName: "app.dashed").frame(width: 20, height: 20).foregroundColor(.secondary)
            }
            Text(app.names.first ?? app.bundleID)
            Spacer()
            Button { editingIndex = index } label: { Image(systemName: "pencil") }.buttonStyle(.borderless)
            Button(role: .destructive) { model.config.apps.removeAll { $0.id == app.id } } label: {
                Image(systemName: "trash")
            }.buttonStyle(.borderless)
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
    }

    // MARK: Footer (verified Apply)

    private var footer: some View {
        HStack(alignment: .center, spacing: 12) {
            ApplyStatusView(outcome: model.outcome) { model.setupEngine() }
            Spacer()
            Button { model.apply() } label: { Text("Apply & Reload").bold() }
                .keyboardShortcut("s", modifiers: .command)
                .disabled(!conflicts.isEmpty)
        }
        .padding(.horizontal, 20).padding(.vertical, 12)
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

    // MARK: trigger labels

    private func modSymbol(_ m: String) -> String {
        if m.contains("Alt") || m == "alt" { return m.hasPrefix("right") ? "Right ⌥" : (m.hasPrefix("left") ? "Left ⌥" : "⌥") }
        if m.contains("Cmd") || m == "cmd" { return m.hasPrefix("right") ? "Right ⌘" : (m.hasPrefix("left") ? "Left ⌘" : "⌘") }
        if m.contains("Ctrl") || m == "ctrl" { return "⌃" }
        if m.contains("Shift") || m == "shift" { return "⇧" }
        return m
    }
    private func triggerLabel(_ a: NavActivator) -> String {
        switch a.kind {
        case "hotkey", "hyper": return Validation.display(mods: a.hotkey.mods, key: a.hotkey.key)
        case "tapModifier": return modSymbol(a.modifier)
        case "doubleTapModifier": return "double-tap \(modSymbol(a.modifier))"
        case "capsLock": return "Caps Lock"
        default: return "—"
        }
    }
    private func triggerSentence(_ a: NavActivator) -> String {
        let l = triggerLabel(a)
        switch a.kind {
        case "tapModifier": return "Press \(l) (tap and release) to enter Navigation Mode. Press Esc to leave."
        default: return "Press \(l) to enter Navigation Mode. Press Esc to leave."
        }
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

/// Engine-health banner: prompts setup until the engine is actually active.
struct EngineBanner: View {
    @ObservedObject var model: AppModel
    var body: some View {
        switch model.health {
        case .active:
            Label("Engine active in Hammerspoon", systemImage: "checkmark.circle.fill")
                .foregroundColor(.green).font(.callout)
        case .installedNotLoaded, .notInstalled:
            VStack(alignment: .leading, spacing: 6) {
                banner(color: .orange, icon: "bolt.horizontal.circle.fill",
                       text: "KeyDeck isn't active yet. Set it up to make your shortcuts work.",
                       button: "Set up engine") { model.setupEngine() }
                if let err = EngineInstaller.lastError() {
                    Text("Last engine error: \(err)").font(.caption).foregroundColor(.red)
                        .textSelection(.enabled).fixedSize(horizontal: false, vertical: true)
                }
            }
        case .noHammerspoon:
            banner(color: .red, icon: "exclamationmark.triangle.fill",
                   text: "Hammerspoon isn't installed. KeyDeck needs it to run.",
                   button: "Get Hammerspoon") { NSWorkspace.shared.open(URL(string: "https://www.hammerspoon.org")!) }
        }
    }
    private func banner(color: Color, icon: String, text: String, button: String, action: @escaping () -> Void) -> some View {
        HStack {
            Label(text, systemImage: icon).foregroundColor(color)
            Spacer()
            Button(button, action: action)
        }
        .padding(12).frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.12)).cornerRadius(8)
    }
}

/// The never-silently-fail Apply checklist.
struct ApplyStatusView: View {
    let outcome: ApplyOutcome
    var onSetup: () -> Void
    var body: some View {
        switch outcome {
        case .idle: EmptyView()
        case .running: HStack(spacing: 6) { ProgressView().controlSize(.small); Text("Applying…").font(.caption) }
        case .done(let navActive):
            Text("✓ Saved  ·  ✓ Reloaded  ·  \(navActive ? "✓ Navigation Mode active" : "Nav Mode off")")
                .font(.caption).foregroundColor(.green).lineLimit(1).truncationMode(.tail)
        case .needsSetup:
            HStack(spacing: 8) {
                Text("Saved, but the engine didn't reload.").font(.caption).foregroundColor(.orange)
                Button("Set up engine", action: onSetup).controlSize(.small)
            }
        case .failed(let msg):
            Text(msg).font(.caption).foregroundColor(.red).lineLimit(1).truncationMode(.middle)
        }
    }
}
