import SwiftUI

/// Compact cheat sheet behind the footer "?" button. The full, always-current
/// list lives in the engine itself: press ? inside Nav Mode.
struct HelpPopover: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Cheat sheet").font(.headline)
            Text("Move: h j k l   ·   Scroll: d u   ·   Top/bottom: gg G")
            Text("Click: i   ·   Right-click: a   ·   Leave: Esc")
            Text("Press ? inside Nav Mode for the full list.")
                .foregroundColor(.secondary)
            Divider()
            Text("Shortcuts not working? Make sure Hammerspoon is running and has Accessibility permission, then click Set up.")
                .font(.caption).foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .font(.callout)
        .padding(14)
        .frame(width: 330)
    }
}
