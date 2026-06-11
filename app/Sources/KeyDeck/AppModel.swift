import SwiftUI
import KeyDeckCore

/// Result of an apply, surfaced as a never-silently-fail checklist.
enum ApplyOutcome: Equatable {
    case idle
    case running
    case done(navActive: Bool)
    case needsSetup
    case failed(String)
}

/// Single source of truth for the UI: the config being edited, license, engine
/// health, and the verified auto-apply flow.
///
/// Apply is automatic: every config mutation arms a short debounce; when it
/// fires the config is saved, Hammerspoon reloads (pathwatcher + URL), and the
/// engine heartbeat is polled to confirm the reload actually happened. A
/// conflicted config is never written — the inline warnings show instead.
@MainActor
final class AppModel: ObservableObject {
    @Published var config: Config {
        didSet { if !suppressAutoApply { scheduleAutoApply() } }
    }
    @Published var outcome: ApplyOutcome = .idle
    @Published var health: EngineInstaller.Health = .notInstalled
    let license = LicenseManager()

    private var suppressAutoApply = false
    private var applyTask: Task<Void, Never>?
    private static let debounceNanos: UInt64 = 800_000_000

    init() {
        config = ConfigStore.load()
        refreshHealth()
    }

    var tier: Tier { license.state.tier }
    var conflicts: [BindingConflict] { Validation.conflicts(in: config) }
    var canAddLauncher: Bool {
        Entitlements.canAddLauncher(currentCount: config.apps.count, tier: tier)
    }

    func refreshHealth() { health = EngineInstaller.health() }

    /// Install the Spoon into the user's Hammerspoon (coexists with their config), then verify.
    func setupEngine() {
        outcome = .running
        if let err = EngineInstaller.install() { outcome = .failed(err); return }
        verifyReload()
    }

    private func scheduleAutoApply() {
        applyTask?.cancel()
        applyTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: Self.debounceNanos)
            guard !Task.isCancelled else { return }
            self?.applyNow()
        }
    }

    /// Flush any pending change immediately (⌘S).
    func applyNow() {
        applyTask?.cancel()
        guard conflicts.isEmpty else { return }   // never persist a conflicted config
        outcome = .running
        let curated = config.curated()
        do {
            try ConfigStore.save(curated)
            suppressAutoApply = true
            config = curated
            suppressAutoApply = false
        } catch {
            outcome = .failed("Couldn't save configuration: \(error.localizedDescription)")
            return
        }
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
}
