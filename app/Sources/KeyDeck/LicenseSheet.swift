import SwiftUI

struct LicenseSheet: View {
    @ObservedObject var license: LicenseManager
    @Environment(\.dismiss) private var dismiss
    @State private var key = ""
    @State private var busy = false
    @State private var error: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("KeyDeck License").font(.headline)
            Text(license.statusText()).foregroundColor(.secondary)

            if license.state.isLicensed {
                Button("Remove license from this Mac") { license.deactivate() }
            } else {
                Text("Enter the license key from your Gumroad receipt:")
                TextField("XXXXXXXX-XXXXXXXX-XXXXXXXX-XXXXXXXX", text: $key)
                    .textFieldStyle(.roundedBorder).font(.system(.body, design: .monospaced))
                if let error { Text(error).foregroundColor(.red).font(.callout) }
                HStack {
                    Button("Buy a license") { NSWorkspace.shared.open(LicenseConfig.buyURL) }
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
