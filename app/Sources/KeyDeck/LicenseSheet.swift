import SwiftUI
import KeyDeckCore

struct LicenseSheet: View {
    @ObservedObject var license: LicenseManager
    @Environment(\.dismiss) private var dismiss
    @State private var key = ""
    @State private var busy = false
    @State private var error: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("KeyDeck License").font(.headline)
            Text(tierLine).foregroundColor(.secondary)

            if license.state.isPro {
                if let email = license.state.email {
                    Text(email).font(.callout).foregroundColor(.secondary)
                }
                Button("Remove license from this Mac") { license.deactivate() }
            } else {
                Button {
                    NSWorkspace.shared.open(LicenseConfig.buyURL)
                } label: {
                    Text("Buy KeyDeck Pro").bold().frame(maxWidth: .infinity)
                }
                .controlSize(.large)

                Text("Already bought it? Enter the license key from your Gumroad receipt:")
                    .font(.callout)
                TextField("XXXXXXXX-XXXXXXXX-XXXXXXXX-XXXXXXXX", text: $key)
                    .textFieldStyle(.roundedBorder).font(.system(.body, design: .monospaced))
                if let error { Text(error).foregroundColor(.red).font(.callout) }
                HStack {
                    Spacer()
                    Button(busy ? "Activating…" : "Activate") { activate() }
                        .disabled(busy || key.trimmingCharacters(in: .whitespaces).isEmpty)
                        .keyboardShortcut(.defaultAction)
                }
            }
            HStack { Spacer(); Button("Done") { dismiss() } }
        }
        .padding(18)
        .frame(width: 440)
    }

    private var tierLine: String {
        switch license.state.tier {
        case .pro:
            return "Pro — unlimited launchers. Thank you!"
        case .trial(let days):
            return "Free trial — everything unlocked, \(days) day\(days == 1 ? "" : "s") left. " +
                   "Afterwards KeyDeck stays free with up to \(Entitlements.freeMaxLaunchers) launchers."
        case .free:
            return "Free plan — up to \(Entitlements.freeMaxLaunchers) launchers. Pro removes the limit."
        }
    }

    private func activate() {
        busy = true; error = nil
        Task {
            let result = await license.activate(key: key)
            busy = false
            switch result {
            case .success: dismiss()
            case .failure(let e): error = e.localizedDescription
            }
        }
    }
}
