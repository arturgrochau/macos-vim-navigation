import SwiftUI
import KeyDeckCore

/// Pro-only display customization, hidden behind the "Customize" button.
struct DisplayCustomizeSheet: View {
    @Binding var monitors: MonitorsFeature
    @Environment(\.dismiss) private var dismiss

    private var jumpEnabled: Binding<Bool> {
        Binding(get: { !monitors.jumpKeys.isEmpty },
                set: { monitors.jumpKeys = $0 ? ["1", "2", "3"] : [] })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Customize Display Switching").font(.headline)
            HStack {
                Text("Next display").frame(width: 130, alignment: .leading)
                ShortcutRecorder(binding: $monitors.nextDisplay).frame(width: 120, height: 26)
            }
            HStack {
                Text("Previous display").frame(width: 130, alignment: .leading)
                ShortcutRecorder(binding: $monitors.prevDisplay).frame(width: 120, height: 26)
            }
            Toggle("Jump to displays with ⌥1 / ⌥2 / ⌥3", isOn: jumpEnabled)
            Toggle("Also tap ⌥ to cycle displays", isOn: $monitors.optionTapCycle)
            HStack { Spacer(); Button("Done") { dismiss() }.keyboardShortcut(.defaultAction) }
        }
        .padding(18)
        .frame(width: 420)
    }
}
