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
    /// Returns what already uses key+mods ("a Nav Mode key" or a launcher name), or nil.
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
            Text("Add App").font(.headline)

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
            // Replacing another launcher is allowed (the old one is removed);
            // a Nav Mode key can only be avoided.
            if !keyIsReserved {
                Button("Replace it", role: .destructive) { commit() }
            }
            Button("Pick another key", role: .cancel) {}
        } message: {
            Text("\(Validation.display(mods: key.mods, key: key.key)) is already \(pendingConflict ?? "in use").")
        }
    }

    private var keyIsReserved: Bool {
        Validation.isReservedNavKey(key: key.key, mods: key.mods)
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
