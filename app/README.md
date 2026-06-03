# KeyDeck — preset editor (SwiftUI)

A minimal native macOS app for editing the engine's configuration: toggle features,
rebind keys, and manage per-app shortcuts, then **Apply & Reload**. It writes
`~/.hammerspoon/keydeck-config.json` (validated against
[`../config/config.schema.json`](../config/config.schema.json)); the engine auto-reloads
on change.

Built as a **SwiftPM package** — no Xcode project, no third-party dependencies.

```
app/
  Package.swift
  Sources/
    KeyDeckCore/     pure logic: Config model, ConfigStore (load/save/reload), Validation
    KeyDeck/         SwiftUI app: App.swift, ContentView.swift
  Tests/KeyDeckCoreTests/   round-trip, partial-config defaults, presets, conflict detection
```

The model in `KeyDeckCore/Config.swift` mirrors the JSON schema and decodes
**tolerantly** — a partial config (or a preset that sets only a few keys) fills the
rest from defaults, exactly like the engine's deep-merge. The UI-only `id` on app
shortcuts is never serialized.

## Build & run

```bash
cd app
swift build           # compile (incl. the SwiftUI app)
swift run KeyDeck      # launch the editor
test/run.sh           # full verification (build + core-logic checks [+ swift test if Xcode])
```

Requires the macOS SDK (Command Line Tools or Xcode). No external packages.

**Note on tests:** `Tests/KeyDeckCoreTests` uses XCTest, which ships with **full
Xcode** — `swift test` won't run under Command Line Tools alone. `test/run.sh`
therefore also runs the same assertions via an XCTest-free runner
(`test/checks/main.swift`) so the logic is verified in either environment.

## What it edits

- **Features:** NAV MODE, visual mode, global cursor, multi-monitor, hide/restore — each a
  toggle, with sub-options (modifiers, focus bindings) revealed when enabled.
- **App shortcuts:** add/remove rows with key, modifiers, bundle ID, display names,
  click target (`center`/`bottom`/`none`), and exit-NAV flag.
- **Presets:** `default` / `developer` / `minimal` from the picker.
- **Conflict detection:** duplicate bindings (within the Global or NAV-MODE namespace)
  are flagged and block Apply until resolved.

## Roadmap

- Live key-capture for rebinding (currently key name + modifier checkboxes).
- Packaged, notarized `.app` bundle + first-run Hammerspoon install (Milestone 3).
- Gumroad licensing for paid presets/features (Milestone 4).
