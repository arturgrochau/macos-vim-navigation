import SwiftUI
import KeyDeckCore

/// The whole app in one window: nav shortcut, display switching, app
/// launchers, and a footer with engine status, apply feedback, license, and
/// help. Changes apply automatically (debounced + verified) — there is no
/// Apply button to learn.
struct MainView: View {
    @StateObject private var model = AppModel()
    @State private var showLicense = false
    @State private var showHelp = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    StatusBanner(model: model)
                    navRow
                    displaysRow
                    LauncherList(model: model, showLicense: $showLicense)
                }
                .padding(20)
            }
            Divider()
            footer
        }
        .frame(width: 480)
        .frame(minHeight: 460)
        .task { await model.license.revalidateIfStale(); model.refreshHealth() }
        .sheet(isPresented: $showLicense) { LicenseSheet(license: model.license) }
        // Hidden ⌘S: flush a pending auto-apply immediately.
        .background(
            Button("") { model.applyNow() }
                .keyboardShortcut("s", modifiers: .command)
                .opacity(0)
        )
    }

    // MARK: Nav Mode shortcut

    private var navRow: some View {
        Card(title: "Nav Mode", isOn: $model.config.features.nav.enabled) {
            HStack(spacing: 10) {
                Text("Enter with").foregroundColor(.secondary)
                ShortcutRecorder(binding: navHotkey).frame(width: 130, height: 26)
                Spacer()
            }
            Text("Press it again or Esc to leave. Inside: h j k l move, d u scroll, ? shows everything.")
                .font(.caption).foregroundColor(.secondary).fixedSize(horizontal: false, vertical: true)
        }
    }

    /// Recording a shortcut always switches the activator to a plain hotkey —
    /// the one supported trigger kind. Old configs with tap-modifier kinds keep
    /// working in the engine until the user records something here.
    private var navHotkey: Binding<KeyBinding> {
        Binding(
            get: { model.config.features.nav.activator.hotkey },
            set: {
                model.config.features.nav.activator.kind = "hotkey"
                model.config.features.nav.activator.hotkey = $0
            })
    }

    // MARK: Displays

    private var displaysRow: some View {
        Card(title: "Displays", isOn: $model.config.features.monitors.enabled) {
            HStack(spacing: 8) {
                Toggle("Switch display when you release", isOn: $model.config.features.monitors.optionTapCycle)
                Picker("", selection: $model.config.features.monitors.cycleModifier) {
                    Text("⌥ Option").tag("alt")
                    Text("⌃ Control").tag("ctrl")
                    Text("⌘ Command").tag("cmd")
                }
                .labelsHidden().frame(width: 120)
                .disabled(!model.config.features.monitors.optionTapCycle)
                Spacer()
            }
            Text("Tap the modifier alone to move to the next display. Using it in shortcuts is unaffected.")
                .font(.caption).foregroundColor(.secondary).fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: Footer

    private var footer: some View {
        HStack(spacing: 10) {
            engineDot
            ApplyStatusView(outcome: model.outcome) { model.setupEngine() }
            Spacer()
            Button(model.license.statusText()) { showLicense = true }
                .buttonStyle(.borderless).foregroundColor(.secondary).font(.caption)
            Button { showHelp = true } label: { Image(systemName: "questionmark.circle") }
                .buttonStyle(.borderless)
                .popover(isPresented: $showHelp) { HelpPopover() }
        }
        .padding(.horizontal, 16).padding(.vertical, 9)
    }

    private var engineDot: some View {
        HStack(spacing: 5) {
            Circle().fill(model.health == .active ? Color.green : Color.secondary.opacity(0.5))
                .frame(width: 8, height: 8)
            Text(model.health == .active ? "Active" : "Off").font(.caption).foregroundColor(.secondary)
        }
        .contentShape(Rectangle())
        .onTapGesture { model.refreshHealth() }
        .help("KeyDeck engine status in Hammerspoon (click to refresh)")
    }
}

/// A titled card with an enable toggle; its content shows only when enabled.
struct Card<Content: View>: View {
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

/// Rendered only when something is broken; the happy path shows nothing here.
struct StatusBanner: View {
    @ObservedObject var model: AppModel
    var body: some View {
        switch model.health {
        case .active:
            EmptyView()
        case .installedNotLoaded, .notInstalled:
            VStack(alignment: .leading, spacing: 6) {
                banner(color: .orange, icon: "bolt.horizontal.circle.fill",
                       text: "KeyDeck isn't active yet. Set it up to make your shortcuts work.",
                       button: "Set up") { model.setupEngine() }
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

/// The never-silently-fail apply checklist (footer).
struct ApplyStatusView: View {
    let outcome: ApplyOutcome
    var onSetup: () -> Void
    var body: some View {
        switch outcome {
        case .idle: EmptyView()
        case .running: HStack(spacing: 6) { ProgressView().controlSize(.small); Text("Applying…").font(.caption) }
        case .done:
            Text("✓ Saved · ✓ Reloaded")
                .font(.caption).foregroundColor(.green).lineLimit(1)
        case .needsSetup:
            HStack(spacing: 8) {
                Text("Saved, but the engine didn't reload.").font(.caption).foregroundColor(.orange)
                Button("Set up", action: onSetup).controlSize(.small)
            }
        case .failed(let msg):
            Text(msg).font(.caption).foregroundColor(.red).lineLimit(1).truncationMode(.middle)
        }
    }
}
