# KeyDeck app (SwiftUI)

The native configuration app: one window, no tabs. Set your Nav Mode shortcut,
toggle display switching (and pick its modifier), and assign keys to your apps.
Changes **auto-apply** — saved, reloaded into Hammerspoon, and verified against the
engine heartbeat (`✓ Saved · ✓ Reloaded` in the footer). There is no Apply button.

It writes `~/.hammerspoon/keydeck-config.json` (contract:
[`../config/config.schema.json`](../config/config.schema.json)); the engine
auto-reloads on change. A conflicted config (duplicate launcher keys, or a
launcher on one of Nav Mode's own keys like `j`) is never written — inline
warnings show until it's fixed.

Built as a **SwiftPM package** — no Xcode project, no third-party dependencies.

```
app/
  Package.swift
  Sources/
    KeyDeckCore/     pure logic: Config model, ConfigStore, Validation, Entitlements
    KeyDeck/         SwiftUI: MainView, AppModel (auto-apply), LauncherList,
                     AddAppSheet, ShortcutRecorder, EngineInstaller, License
  Tests/KeyDeckCoreTests/   round-trip, old-config decode, conflicts, trial math
```

The model in `KeyDeckCore/Config.swift` mirrors the JSON schema and decodes
**tolerantly** — a partial or old config fills the rest from defaults, exactly like
the engine's deep-merge. On save the app writes a *curated* config (only what the
UI shows), so the running engine never has hidden shortcuts.

## Build & run

```bash
cd app
swift build           # compile
swift run KeyDeck     # launch via SwiftPM (dev)
test/run.sh           # full verification (build + core checks [+ swift test if Xcode])

# Build a proper, double-clickable macOS app bundle:
./bundle.sh           # → app/KeyDeck.app  (release, ad-hoc signed, Spoon embedded)
open KeyDeck.app
```

Requires the macOS SDK (Command Line Tools or Xcode). No external packages.

**Note on tests:** `Tests/KeyDeckCoreTests` uses XCTest, which ships with **full
Xcode** — `swift test` won't run under Command Line Tools alone. `test/run.sh`
therefore also runs the same assertions via an XCTest-free runner
(`test/checks/main.swift`) so the logic is verified in either environment.

## First run

No wizard. With no launchers configured, the list shows suggestions from the apps
actually installed on the Mac — one click to keep them. If the engine isn't set up,
a banner offers **Set up**: it installs `KeyDeck.spoon` into
`~/.hammerspoon/Spoons` and appends a marker-guarded 2-line loader to `init.lua`
(backed up first) — your own Hammerspoon config is untouched.

## Licensing (Gumroad)

14-day trial with everything unlocked, then **free forever with up to 3 app
launchers**; a Pro license removes the cap. Nothing ever stops working — the cap
only blocks *adding* launchers. Verification uses the Gumroad License API +
machine binding + a cached receipt (works offline after activation; silent weekly
re-verification does **not** consume activations).

**To enable for your product** — set the constants in
`Sources/KeyDeck/License.swift` → `LicenseConfig` (marked `TODO(release)`):

```swift
static let productID = "your_gumroad_product_id"   // Product → Advanced → product_id
static let buyURL    = URL(string: "https://gumroad.com/l/your-permalink")!
static let maxActivations = 3                       // per-key machine cap
```

Until `productID` is set, activation returns a clear "not configured" message and
the trial logic still works. Client-side verification + machine binding + cached
receipt is reasonable indie protection; a small server would be needed for
stronger guarantees.
