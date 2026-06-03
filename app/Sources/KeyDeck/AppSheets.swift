import SwiftUI
import KeyDeckCore

/// Searchable list of installed apps (icon + name).
private struct AppList: View {
    let apps: [InstalledApp]
    @Binding var selection: InstalledApp?

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(apps) { app in
                    HStack(spacing: 8) {
                        Image(nsImage: app.icon).resizable().frame(width: 18, height: 18)
                        Text(app.name)
                        Spacer()
                    }
                    .padding(.horizontal, 8).padding(.vertical, 5)
                    .background(selection == app ? Color.accentColor.opacity(0.18) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                    .contentShape(Rectangle())
                    .onTapGesture { selection = app }
                }
            }
            .padding(4)
        }
    }
}

/// Add a launcher: pick an installed app, then press the key to launch it.
struct AddAppSheet: View {
    var conflictName: (String, [String]) -> String?
    var onAdd: (AppShortcut) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var apps: [InstalledApp] = []
    @State private var search = ""
    @State private var selected: InstalledApp?
    @State private var key = KeyBinding()
    @State private var pendingConflict: String?

    private var filtered: [InstalledApp] {
        search.isEmpty ? apps : apps.filter { $0.name.localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add App Launcher").font(.headline)

            TextField("Search your apps…", text: $search).textFieldStyle(.roundedBorder)
            AppList(apps: filtered, selection: $selected)
                .frame(height: 240)
                .background(Color(nsColor: .textBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(nsColor: .separatorColor)))

            HStack(spacing: 10) {
                if let app = selected {
                    Image(nsImage: app.icon).resizable().frame(width: 18, height: 18)
                    Text(app.name).bold()
                    Text("→").foregroundColor(.secondary)
                    Text("press key:")
                    ShortcutRecorder(binding: $key, captureModifiers: false).frame(width: 110, height: 26)
                } else {
                    Text("Select an app above.").foregroundColor(.secondary)
                }
                Spacer()
            }

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }.keyboardShortcut(.cancelAction)
                Button("Add") { attemptAdd() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(selected == nil || key.key.isEmpty)
            }
        }
        .padding(18)
        .frame(width: 440)
        .onAppear { apps = AppCatalog.installed() }
        .alert("Key already in use", isPresented: Binding(get: { pendingConflict != nil }, set: { if !$0 { pendingConflict = nil } })) {
            Button("Replace", role: .destructive) { commit() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("\(pendingConflict ?? "Another launcher") already uses \(Validation.display(mods: key.mods, key: key.key)).")
        }
    }

    private func attemptAdd() {
        guard selected != nil, !key.key.isEmpty else { return }
        if let other = conflictName(key.key, key.mods) { pendingConflict = other } else { commit() }
    }

    private func commit() {
        guard let app = selected else { return }
        onAdd(AppShortcut(key: key.key, mods: key.mods, bundleID: app.id,
                          names: [app.name], clickTarget: "center", exitNav: true))
        dismiss()
    }
}

/// Edit an existing launcher: key, app, and (advanced) position / behavior / bundle ID.
struct AppEditorSheet: View {
    @Binding var app: AppShortcut
    var conflictName: (String, [String]) -> String?
    @Environment(\.dismiss) private var dismiss

    @State private var apps: [InstalledApp] = []
    @State private var showAdvanced = false

    private var keyBinding: Binding<KeyBinding> {
        Binding(get: { KeyBinding(mods: app.mods, key: app.key) },
                set: { app.mods = $0.mods; app.key = $0.key })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Edit Launcher").font(.headline)

            HStack {
                Text("Launch").frame(width: 70, alignment: .leading)
                Picker("", selection: bundleSelection) {
                    ForEach(apps) { Text($0.name).tag($0.id as String?) }
                    if !apps.contains(where: { $0.id == app.bundleID }) {
                        Text(app.names.first ?? app.bundleID).tag(app.bundleID as String?)
                    }
                }.labelsHidden()
            }

            HStack {
                Text("Key").frame(width: 70, alignment: .leading)
                ShortcutRecorder(binding: keyBinding, captureModifiers: false).frame(width: 110, height: 26)
                Text("(press while in Navigation Mode)").font(.caption).foregroundColor(.secondary)
            }
            if let other = conflictName(app.key, app.mods), !app.key.isEmpty {
                Text("⚠ \(other) also uses \(Validation.display(mods: app.mods, key: app.key))")
                    .font(.caption).foregroundColor(.orange)
            }

            DisclosureGroup("Advanced", isExpanded: $showAdvanced) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Click").frame(width: 70, alignment: .leading)
                        Picker("", selection: $app.clickTarget) {
                            Text("Center of window").tag("center")
                            Text("Input box (bottom)").tag("bottom")
                            Text("Don't click").tag("none")
                        }.labelsHidden().frame(width: 200)
                    }
                    Toggle("Return to normal typing after launch", isOn: $app.exitNav)
                    HStack {
                        Text("Bundle ID").frame(width: 70, alignment: .leading)
                        Text(app.bundleID).font(.caption).foregroundColor(.secondary).textSelection(.enabled)
                    }
                }
                .padding(.top, 6)
            }

            HStack { Spacer(); Button("Done") { dismiss() }.keyboardShortcut(.defaultAction) }
        }
        .padding(18)
        .frame(width: 420)
        .onAppear { apps = AppCatalog.installed() }
    }

    private var bundleSelection: Binding<String?> {
        Binding(
            get: { app.bundleID },
            set: { newID in
                guard let newID, let picked = apps.first(where: { $0.id == newID }) else { return }
                app.bundleID = picked.id
                app.names = [picked.name]
            })
    }
}
