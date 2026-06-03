import SwiftUI
import KeyDeckCore

/// Hidden-by-default trigger picker. The main screen only shows "Trigger: ^= [Change]";
/// this is where the implementation choices live.
struct TriggerChangeSheet: View {
    @Binding var activator: NavActivator
    @Environment(\.dismiss) private var dismiss
    @State private var capsEnabled = CapsLockSetup.isEnabled

    private var current: TriggerPreset { TriggerPreset.from(activator) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Change Trigger").font(.headline)
            Text("How you enter Navigation Mode.").font(.callout).foregroundColor(.secondary)

            ForEach(TriggerPreset.ordered) { p in
                Button { activator = p.activator(existing: activator) } label: {
                    HStack(spacing: 8) {
                        Image(systemName: current == p ? "largecircle.fill.circle" : "circle")
                            .foregroundColor(current == p ? .accentColor : .secondary)
                        Text(p.label)
                        Spacer()
                    }.contentShape(Rectangle())
                }.buttonStyle(.plain)
            }

            if current == .custom || activator.kind == "hyper" {
                HStack {
                    Text("Shortcut").frame(width: 80, alignment: .leading)
                    ShortcutRecorder(binding: $activator.hotkey).frame(width: 130, height: 26)
                }
            }
            if activator.kind == "tapModifier" {
                Toggle("Activate on release (ignored when used in a shortcut)", isOn: $activator.onRelease)
                    .font(.callout)
            }
            if activator.kind == "capsLock" {
                HStack(spacing: 10) {
                    if capsEnabled {
                        Label("Set up", systemImage: "checkmark.circle.fill").foregroundColor(.green)
                        Button("Remove") { CapsLockSetup.disable(); capsEnabled = false }
                    } else {
                        Button("Set up Caps Lock") { capsEnabled = CapsLockSetup.enable() }
                        Text("Remaps Caps Lock → F18 (reversible).").font(.caption).foregroundColor(.secondary)
                    }
                }
            }

            HStack { Spacer(); Button("Done") { dismiss() }.keyboardShortcut(.defaultAction) }
        }
        .padding(18)
        .frame(width: 400)
    }
}
