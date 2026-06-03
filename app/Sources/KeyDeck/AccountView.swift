import SwiftUI
import KeyDeckCore

/// The Account tab — monetization kept separate from functional settings.
struct AccountView: View {
    @ObservedObject var model: AppModel
    @Binding var showLicense: Bool
    @State private var showDev = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Account").font(.title2).bold()

            GroupBox {
                VStack(alignment: .leading, spacing: 10) {
                    if model.isPro {
                        Label("Pro", systemImage: "checkmark.seal.fill").foregroundColor(.green).font(.headline)
                        Text(model.license.statusText()).foregroundColor(.secondary)
                        Text("Unlimited app launchers and display customization.").font(.callout).foregroundColor(.secondary)
                        Button("Manage license…") { showLicense = true }
                    } else {
                        Text("Free Plan").font(.headline)
                        Text("Up to \(Entitlements.freeMaxLaunchers) app launchers and 3 display shortcuts (⌥1 / ⌥2 / ⌥3).")
                            .foregroundColor(.secondary).fixedSize(horizontal: false, vertical: true)
                        Text("Upgrade for unlimited mappings and display customization.")
                            .font(.callout).foregroundColor(.secondary)
                        HStack {
                            Button("Upgrade to Pro") { NSWorkspace.shared.open(LicenseConfig.buyURL) }
                                .buttonStyle(.borderedProminent)
                            Button("Enter license key") { showLicense = true }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(6)
            }

            Spacer()

            HStack {
                Button("Developer Settings…") { showDev = true }.controlSize(.small)
                Spacer()
                Button { NSWorkspace.shared.open(URL(string: "https://github.com/arturgrochau")!) } label: {
                    Text("Made by Artur Grochau").font(.caption)
                }.buttonStyle(.link)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .sheet(isPresented: $showDev) { DeveloperSettingsSheet(model: model) }
    }
}
