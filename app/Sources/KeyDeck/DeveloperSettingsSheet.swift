import SwiftUI
import KeyDeckCore

/// Power-user settings, reached only from Account → Developer Settings.
struct DeveloperSettingsSheet: View {
    @ObservedObject var model: AppModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Developer Settings").font(.headline)
            Text("Most people never need these.").font(.callout).foregroundColor(.secondary)

            Toggle("Visual selection mode", isOn: $model.config.features.visual.enabled)
            Toggle("Global cursor movement (⌥⌘⇧ + h / j / k / l)", isOn: $model.config.features.cursor.enabled)
            Toggle("Debug logging", isOn: $model.config.debug)

            Text("Custom Hammerspoon (runs after the engine loads)")
                .font(.caption).foregroundColor(.secondary)
            TextEditor(text: $model.config.customLua)
                .font(.system(.caption, design: .monospaced))
                .frame(height: 90)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(nsColor: .separatorColor)))

            HStack {
                Button("Reveal config file") {
                    NSWorkspace.shared.selectFile(ConfigStore.path, inFileViewerRootedAtPath: "")
                }
                Button("Reset to defaults") { model.config = .default }
                Spacer()
                Button("Done") { dismiss() }.keyboardShortcut(.defaultAction)
            }
        }
        .padding(18)
        .frame(width: 470)
    }
}
