import SwiftUI
import KeyDeckCore

/// The launcher list — the centerpiece. Each detected app gets a key usable
/// inside Nav Mode; pressing it exits Nav Mode and launches/focuses the app.
/// The key capsule is an inline recorder (click → press a key); conflicts show
/// inline and block auto-apply until resolved. With no launchers configured,
/// the list doubles as onboarding: suggestions from the apps actually installed.
struct LauncherList: View {
    @ObservedObject var model: AppModel
    @Binding var showLicense: Bool

    @State private var appsByID: [String: InstalledApp] = [:]
    @State private var showAdd = false
    @State private var showUpgrade = false
    @State private var suggestions: [AppShortcut] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Apps").font(.headline)
                Text("press its key in Nav Mode to launch").font(.caption).foregroundColor(.secondary)
                Spacer()
                Button { if model.canAddLauncher { showAdd = true } else { showUpgrade = true } } label: {
                    Label("Add", systemImage: "plus")
                }
            }
            if model.config.apps.isEmpty {
                emptyState
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(model.config.apps.enumerated()), id: \.element.id) { idx, app in
                        row(app, index: idx)
                        if idx < model.config.apps.count - 1 { Divider() }
                    }
                }
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(nsColor: .separatorColor)))
            }
            if case .free = model.tier {
                HStack(spacing: 4) {
                    Text("Free: \(model.config.apps.count)/\(Entitlements.freeMaxLaunchers) launchers")
                        .font(.caption).foregroundColor(.secondary)
                    Button("Upgrade") { showLicense = true }
                        .buttonStyle(.borderless).font(.caption)
                }
            }
        }
        .onAppear {
            let installed = AppCatalog.installed()
            appsByID = Dictionary(installed.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
            suggestions = SuggestedLaunchers.suggestions(installed: installed.map { ($0.id, $0.name) })
        }
        .sheet(isPresented: $showAdd) {
            AddAppSheet(
                conflictName: { key, mods in conflictDescription(key: key, mods: mods, excludingID: nil) },
                onAdd: { s in
                    model.config.apps.removeAll { $0.key.lowercased() == s.key.lowercased() && Set($0.mods) == Set(s.mods) }
                    model.config.apps.append(s)
                })
        }
        .alert("Upgrade to Pro", isPresented: $showUpgrade) {
            Button("Upgrade…") { showLicense = true }
            Button("Not now", role: .cancel) {}
        } message: {
            Text("The free plan includes \(Entitlements.freeMaxLaunchers) app launchers. Upgrade for unlimited.")
        }
    }

    // MARK: rows

    private func row(_ app: AppShortcut, index: Int) -> some View {
        let keyBinding = Binding<KeyBinding>(
            get: { KeyBinding(mods: app.mods, key: app.key) },
            set: { nb in
                guard model.config.apps.indices.contains(index) else { return }
                model.config.apps[index].mods = nb.mods
                model.config.apps[index].key = nb.key
            })
        return HStack(spacing: 10) {
            ShortcutRecorder(binding: keyBinding, captureModifiers: false)
                .frame(width: 64, height: 24)
            Text("→").foregroundColor(.secondary)
            if let a = appsByID[app.bundleID] {
                Image(nsImage: a.icon).resizable().frame(width: 20, height: 20)
            } else {
                Image(systemName: "app.dashed").frame(width: 20, height: 20).foregroundColor(.secondary)
            }
            Text(app.names.first ?? app.bundleID)
            if let warning = warningText(for: app) {
                Label(warning, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption).foregroundColor(.orange).lineLimit(1)
            }
            Spacer()
            Button(role: .destructive) { model.config.apps.removeAll { $0.id == app.id } } label: {
                Image(systemName: "trash")
            }.buttonStyle(.borderless)
        }
        .padding(.horizontal, 12).padding(.vertical, 7)
    }

    private func warningText(for app: AppShortcut) -> String? {
        guard !app.key.isEmpty else { return "no key set" }
        if Validation.isReservedNavKey(key: app.key, mods: app.mods) {
            return "\(Validation.display(mods: app.mods, key: app.key)) is a Nav Mode key"
        }
        if let other = conflictDescription(key: app.key, mods: app.mods, excludingID: app.id) {
            return "also \(other)"
        }
        return nil
    }

    private func conflictDescription(key: String, mods: [String], excludingID: UUID?) -> String? {
        if Validation.isReservedNavKey(key: key, mods: mods) { return "a Nav Mode key" }
        return model.config.appLauncherName(forKey: key, mods: mods, excludingID: excludingID)
    }

    // MARK: empty state = onboarding

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("We found these on your Mac — keep the ones you want:")
                .font(.callout).foregroundColor(.secondary)
            VStack(spacing: 0) {
                ForEach(suggestions) { s in
                    HStack(spacing: 10) {
                        Text(s.key.uppercased())
                            .font(.system(.body, design: .rounded)).bold()
                            .frame(width: 24)
                            .padding(.vertical, 2).padding(.horizontal, 4)
                            .background(Color.accentColor.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                        if let a = appsByID[s.bundleID] {
                            Image(nsImage: a.icon).resizable().frame(width: 18, height: 18)
                        }
                        Text(s.names.first ?? s.bundleID)
                        Spacer()
                    }
                    .padding(.horizontal, 10).padding(.vertical, 5)
                }
            }
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(nsColor: .separatorColor)))
            HStack {
                Button("Use these") { model.config.apps = suggestions }
                    .keyboardShortcut(.defaultAction)
                Button("Start empty") { showAdd = true }.buttonStyle(.borderless)
            }
        }
    }
}
