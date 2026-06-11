# KeyDeck

**Vim-inspired keyboard navigation for macOS, powered by [Hammerspoon](https://www.hammerspoon.org).**

KeyDeck does three things, and does them fast:

1. **Nav Mode** — press your shortcut (default `⌃=`) and your keyboard takes over the pointer:
   `h j k l` move, `d u` scroll, `gg / G` jump to top/bottom, `i` clicks, `a` right-clicks.
   Press `?` inside for the full list, `Esc` to leave.
2. **Switch displays on release** — tap `⌥` (Option) alone and the pointer jumps to your next
   monitor. Release-triggered and idle-guarded, so `⌥`-shortcuts are never affected.
   The modifier is configurable (`⌥` / `⌃` / `⌘`).
3. **App launchers** — give your apps keys. In Nav Mode, press the key: Nav Mode exits
   instantly and the app launches or comes to focus.

Everything runs inside Hammerspoon as a standard [Spoon](https://www.hammerspoon.org/Spoons/)
— it coexists with any existing Hammerspoon setup.

## Install

**Requirement:** [Hammerspoon](https://www.hammerspoon.org) (free), with Accessibility permission granted.

### Option A — the KeyDeck app (recommended)

A small native app to set your shortcut, toggle display switching, and assign app keys —
changes apply and verify automatically.

```bash
cd app && ./bundle.sh    # builds app/KeyDeck.app
open KeyDeck.app         # click "Set up" inside
```

### Option B — script

```bash
scripts/install.sh           # installs the Spoon + a 2-line loader (init.lua backed up)
scripts/install.sh --config  # …and an example keydeck-config.json
```

### Option C — manual (plain Spoon)

Copy `Spoons/KeyDeck.spoon` into `~/.hammerspoon/Spoons/`, then add to your `init.lua`:

```lua
hs.loadSpoon("KeyDeck")
spoon.KeyDeck:start()
```

Optionally bind the Nav Mode toggle the Spoon-conventional way:

```lua
spoon.KeyDeck:bindHotkeys({ toggle = { { "ctrl" }, "=" } })
```

## Configuration

The app writes `~/.hammerspoon/keydeck-config.json`; the engine reloads automatically when
it changes. You can also edit it by hand — any subset of keys is valid (everything else
falls back to defaults). See [`config/keydeck-config.example.json`](config/keydeck-config.example.json)
and the full contract in [`config/config.schema.json`](config/config.schema.json).

## Repo layout

| Path | What it is |
|---|---|
| `Spoons/KeyDeck.spoon/` | The engine — a standard Hammerspoon Spoon (canonical source) |
| `app/` | The SwiftUI configuration app ([details](app/README.md)) |
| `config/` | Config schema + example config |
| `scripts/install.sh` | CLI installer (mirrors the app's "Set up") |
| `test/run.sh` | Offline test suite (no Hammerspoon needed) |

## Pricing

Free 14-day trial with everything unlocked; afterwards KeyDeck stays free with up to
3 app launchers. A Pro license (one-time, via Gumroad) removes the limit.

## Release checklist

- [ ] Set the real Gumroad product ID in `app/Sources/KeyDeck/License.swift`
      (`LicenseConfig.productID`) and verify `buyURL` — activation fails with
      "not configured" until then.
- [ ] `test/run.sh` and `app/test/run.sh` green.
- [ ] `app/bundle.sh` and a manual smoke test (set shortcut → auto-apply →
      `✓ Saved · ✓ Reloaded` → Nav Mode works).

## License

MIT — see [LICENSE](LICENSE). Built by [Artur Grochau](https://github.com/arturgrochau).
