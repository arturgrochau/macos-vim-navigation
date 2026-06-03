# KeyDeck Engine

The **configurable Hammerspoon engine** behind the macOS keyboard-navigation system.

The original project shipped as a single hand-edited `init.lua`. This engine refactors
that same behavior into a **config-driven** backend: a thin bootstrap loads a JSON config
and wires up only the feature modules you enable. A separate SwiftUI preset editor (see the
repo plan) writes that JSON — so end users toggle features and rebind keys in a GUI instead
of editing Lua.

With **no config file present, the engine reproduces the original `main`-branch behavior** exactly.

## Architecture

```
SwiftUI editor ──writes──▶ ~/.hammerspoon/keydeck-config.json ──read──▶ engine (this folder)
                                      ▲
                       config/config.schema.json  (the contract, validates both sides)
```

The JSON config is the only coupling point. The engine never knows the GUI exists; the GUI
never executes Lua. New feature = new module file + new schema block.

```
engine/
  init.lua            thin bootstrap: load config → build ctx → require enabled modules
  config.lua          read keydeck-config.json, deep-merge over defaults
  defaults.lua        canonical default config (mirrors config/presets/default.json)
  lib/
    core.lua          shared state + mouse/scroll/drag/hold-to-repeat helpers (one ctx, passed to all modules)
    overlay.lua       "-- NORMAL --" / "-- VISUAL MODE --" on-screen overlays
  modules/            each exposes M.setup(ctx) and registers bindings only when enabled
    nav.lua           modal lifecycle, hjkl movement, scroll, clicks, focus cycle, gg/G
    visual.lua        visual selection mode + yank/paste
    apps.lua          per-app launch/focus shortcuts (data-driven from cfg.apps)
    cursor.lua        global ⌥⌘⇧ + hjkl pointer movement (outside NAV MODE)
    monitors.lua      option-tap screen cycle, ⌥1/2/3 jump, ⌥0/9/8 jump+click, focus left/right
    windows.lua       hide frontmost app / restore all hidden+minimized windows
```

## Install

Hammerspoon auto-loads `~/.hammerspoon/init.lua`, so the engine folder becomes your
Hammerspoon config directory:

```bash
# Back up any existing config first!
cp -R engine/ ~/.hammerspoon/
# or, for development, symlink the repo:
ln -s "$PWD/engine" ~/.hammerspoon
```

Then open Hammerspoon and **Reload Config** (or press `⌥R`). A "KeyDeck loaded" alert confirms
which preset is active. No `keydeck-config.json` = defaults.

## Configuration

Drop a `keydeck-config.json` in `~/.hammerspoon/`. It only needs the keys you want to override;
everything else falls back to `defaults.lua`. Start from a preset:

```bash
cp config/presets/developer.json ~/.hammerspoon/keydeck-config.json
```

Presets in `config/presets/`:

| Preset       | What it enables                                                        |
| ------------ | ---------------------------------------------------------------------- |
| `default`    | Original behavior: NAV MODE, visual mode, multi-monitor, app shortcuts |
| `developer`  | Adds global cursor (`⌥⌘⇧hjkl`), hide/restore, AI-app shortcuts         |
| `minimal`    | NAV MODE + screen switching only (no visual mode, no app shortcuts)    |

### Config shape (abridged)

```jsonc
{
  "preset": "developer",
  "tuning": {
    "scrollStep": 62,
    "globalCursorStep": 180,
    "optionReleaseIdleSeconds": 2.0   // on-release, no-conflict guard for ⌥ tap
  },
  "features": {
    "nav":      { "enabled": true, "enterKeys": [{ "mods": ["ctrl","alt","cmd"], "key": "space" }] },
    "visual":   { "enabled": true },
    "cursor":   { "enabled": true, "mods": ["alt","cmd","shift"], "keys": { "left":"h","down":"j","up":"k","right":"l","click":"i" } },
    "monitors": { "enabled": true, "skipVirtualDisplayPattern": "16:9|HiDPI|Virtual",
                  "jumpKeys": ["1","2","3"], "jumpClickKeys": ["0","9","8"] },
    "windows":  { "enabled": true, "hide": { "mods": ["alt","cmd"], "key": "h" } }
  },
  "apps": [
    { "key": "c", "mods": [],        "bundleID": "com.openai.chat", "names": ["ChatGPT"], "clickTarget": "bottom", "exitNav": true },
    { "key": "c", "mods": ["shift"], "bundleID": "com.anthropic.claudefordesktop", "names": ["Claude"], "clickTarget": "center" }
  ]
}
```

The full contract — every key, type, and allowed value — is in
[`config/config.schema.json`](../config/config.schema.json).

`clickTarget` is `center` | `bottom` | `none`. To add an app shortcut, append an entry to
`apps` with its bundle ID (find one via `osascript -e 'id of app "AppName"'`).

## How the no-conflict ⌥ tap works

A bare **Option tap** cycles the pointer to the next physical screen — but only if no other key
was pressed and the keyboard has been idle for `optionReleaseIdleSeconds`. This is why
`Cmd+J`, `⌥D`/`⌥U` scroll, etc. keep working without ever triggering a screen switch. The logic
lives in `modules/monitors.lua`.

## Verifying changes

There is no headless Hammerspoon test runner, so verification is two-tiered:

1. **Static / load test** (no Hammerspoon needed):
   ```bash
   # syntax-check every Lua file
   for f in engine/init.lua engine/*.lua engine/lib/*.lua engine/modules/*.lua; do
     luajit -e "assert(loadfile('$f'))" && echo "ok $f"
   done
   # full load test against a mock hs API (exercises every module's setup)
   luajit engine/test/load_harness.lua "$PWD/engine"
   ```
2. **Live test:** install per above, Reload Config, and confirm the "KeyDeck loaded" alert plus
   the behaviors for your preset (NAV MODE entry, hjkl, screen switching, app shortcuts).
