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
swift run KeyDeck      # launch via SwiftPM (dev)
test/run.sh           # full verification (build + core-logic checks [+ swift test if Xcode])

# Build a proper, double-clickable macOS app bundle (dock icon, window, menu):
bundle.sh             # → app/KeyDeck.app  (release, ad-hoc signed)
open KeyDeck.app
```

Requires the macOS SDK (Command Line Tools or Xcode). No external packages.

**Note on tests:** `Tests/KeyDeckCoreTests` uses XCTest, which ships with **full
Xcode** — `swift test` won't run under Command Line Tools alone. `test/run.sh`
therefore also runs the same assertions via an XCTest-free runner
(`test/checks/main.swift`) so the logic is verified in either environment.

## What it edits

The UI is organized around the three things people actually do — not the config structure.

- **Navigation Mode:** one toggle + how you enter it (tap **Right ⌘** / Right ⌥ / F12 /
  a custom shortcut you record). Plain-language explanation of what the mode does.
- **Display Switching:** tap ⌥ for the next display, recordable **Next / Previous display**
  shortcuts, and ⌥1 / ⌥2 / ⌥3 to jump to a specific screen.
- **App Launchers:** a simple `key → App` list. **Add App** searches your *installed* apps
  (icons included) — no bundle IDs to type. Per-launcher editing hides position / click
  behavior / bundle ID behind **Advanced**.

Shortcuts use a click-to-record field (the standard macOS pattern), not modifier checkboxes.
Duplicate keys are flagged and block **Apply** until resolved. On Apply, the editor writes a
*curated* config (only what it shows), so the running engine never has hidden shortcuts.

Visual mode, global cursor movement, hide/restore and scroll gestures remain in the engine
but are intentionally not surfaced, to keep the editor minimal.

## First run & triggers

- **Onboarding** (shown when no config exists): explains the three concepts and proposes
  launchers from the apps you actually have installed — pick and **Continue**.
- **Trigger presets:** **Tap Right ⌥ (on release)** by default — entering Nav Mode only when
  Option is tapped *alone*, so it never steals your ⌥-shortcuts. Alternatives: Double-tap ⌥,
  Caps Lock (one-click `hidutil` remap → F18 + LaunchAgent), Control + =, Hyper key, Custom.
- **Advanced** (collapsed): Visual mode, Global cursor, Debug logging, Reveal config, License.
- Press **?** inside Nav Mode for an on-screen list of every binding.

## Licensing (Gumroad)

14-day trial, then **Apply** is gated until a license is entered (your last-applied config keeps
running). Verification uses the **Gumroad License API** + machine binding + a cached receipt
(works offline after activation).

**To enable it for your product:** create the product on Gumroad, enable license keys, then set
the constants in `Sources/KeyDeck/License.swift` → `LicenseConfig`:

```swift
static let productID = "your_gumroad_product_id"   // Product → Advanced → product_id
static let buyURL    = URL(string: "https://gumroad.com/l/your-permalink")!
static let maxActivations = 3                       // per-key machine cap
```

Until `productID` is set, activation returns a clear "not configured" message and the trial logic
still works. Note: client-side verification + machine binding + cached receipt is reasonable indie
protection; a small server would be needed for stronger guarantees (a later step).

## Roadmap

- Notarized `.app` + first-run Hammerspoon install check (Milestone 3, partial: `bundle.sh` exists).
- Optional licensing server for stronger anti-piracy.
