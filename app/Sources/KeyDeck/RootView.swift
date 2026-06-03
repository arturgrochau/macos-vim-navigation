import SwiftUI
import KeyDeckCore

/// Result of an Apply, surfaced as a never-silently-fail checklist.
enum ApplyOutcome: Equatable {
    case idle
    case running
    case done(navActive: Bool)
    case needsSetup
    case failed(String)
}

/// Single source of truth for the UI: the config being edited, license, engine health,
/// and the verified Apply flow.
@MainActor
final class AppModel: ObservableObject {
    @Published var config: Config
    @Published var outcome: ApplyOutcome = .idle
    @Published var health: EngineInstaller.Health = .notInstalled
    @Published var showOnboarding: Bool
    let license = LicenseManager()

    init() {
        config = ConfigStore.load()
        showOnboarding = !ConfigStore.fileExists
        refreshHealth()
    }

    var isPro: Bool { license.isPro }
    func refreshHealth() { health = EngineInstaller.health() }

    /// Install the Spoon into the user's Hammerspoon (coexists with their config), then verify.
    func setupEngine() {
        outcome = .running
        if let err = EngineInstaller.install() { outcome = .failed(err); return }
        verifyReload()
    }

    /// Save the curated config, reload Hammerspoon, and verify the engine actually reloaded.
    func apply() {
        outcome = .running
        let curated = config.curatedForEssentials()
        do { try ConfigStore.save(curated); config = curated }
        catch { outcome = .failed("Couldn't save configuration: \(error.localizedDescription)"); return }
        EngineInstaller.reloadHammerspoon()
        verifyReload()
    }

    /// Poll the engine heartbeat for up to ~3s to confirm the reload took effect.
    private func verifyReload() {
        let before = EngineStatus.read()?.loadedAt ?? 0
        Task {
            for _ in 0..<15 {
                try? await Task.sleep(nanoseconds: 200_000_000)
                if let s = EngineStatus.read(), s.loadedAt > before {
                    outcome = .done(navActive: s.navEnabled)
                    refreshHealth()
                    return
                }
            }
            outcome = .needsSetup
            refreshHealth()
        }
    }

    func createDefaults(_ apps: [AppShortcut]) {
        if !apps.isEmpty { config.apps = apps }
        try? ConfigStore.save(config.curatedForEssentials())
        setupEngine()
    }
}

struct RootView: View {
    @StateObject private var model = AppModel()
    @State private var showLicense = false

    var body: some View {
        TabView {
            SettingsView(model: model, showLicense: $showLicense)
                .tabItem { Label("Settings", systemImage: "slider.horizontal.3") }
            LearnView()
                .tabItem { Label("Learn", systemImage: "book") }
            AccountView(model: model, showLicense: $showLicense)
                .tabItem { Label("Account", systemImage: "person.crop.circle") }
        }
        .frame(minWidth: 580, minHeight: 600)
        .task { await model.license.revalidateIfStale(); model.refreshHealth() }
        .sheet(isPresented: $model.showOnboarding) {
            OnboardingView { chosen in
                model.createDefaults(chosen)
                model.showOnboarding = false
            }
        }
        .sheet(isPresented: $showLicense) { LicenseSheet(license: model.license) }
    }
}
