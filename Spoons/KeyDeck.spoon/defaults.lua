-- Canonical default configuration for the navigation engine.
-- This table is the source of truth the engine falls back to when no
-- ~/.hammerspoon/keydeck-config.json is present, and it mirrors
-- config/presets/default.json (which reproduces the original main-branch behavior).
--
-- The SwiftUI preset editor writes keydeck-config.json; config.lua deep-merges it
-- over this table, so a user config only needs to specify the keys it overrides.
return {
  preset = "default",
  -- When true, the engine emits extra hs.alert diagnostics (toggled from Developer Settings).
  debug = false,
  -- Optional raw Lua run after modules load (Developer Settings escape hatch).
  customLua = "",

  -- Numeric tunables shared across modules.
  tuning = {
    scrollStep             = 62,      -- pixels per scroll tick
    scrollInitialDelay     = 0.15,    -- delay before hold-to-repeat scrolling kicks in
    scrollRepeatInterval   = 0.05,    -- interval between repeated scrolls while held
    directionInitialDelay  = 0.05,    -- delay before hold-to-repeat cursor movement
    directionRepeatInterval = 0.15,   -- interval between repeated cursor moves while held

    -- Option-tap screen cycling: the "on-release, no-conflict" guard.
    -- A bare Option tap only fires the screen-cycle if no other key was pressed
    -- and the keyboard has been idle for at least this many seconds. This is what
    -- lets e.g. Cmd+J keep working without triggering a screen switch.
    optionReleaseIdleSeconds = 2.0,
    optionScrollAmount       = 260,   -- pixels for option+d / option+u global scroll
  },

  -- Feature modules. Each module only registers its bindings when enabled.
  features = {
    nav = {
      enabled = true,
      -- Primary way to toggle NAV MODE.
      --   kind = "tapModifier"       → tap `modifier` alone (guarded; see onRelease)
      --        | "doubleTapModifier" → tap `modifier` twice quickly
      --        | "hotkey" | "hyper"  → bind `hotkey` as a toggle shortcut
      --        | "capsLock"          → bind F18 (the GUI remaps Caps Lock → F18)
      --   modifier = alt|cmd|ctrl|shift (either side) or rightAlt|leftAlt|rightCmd|… (specific)
      --   onRelease = true → fire only when the tapped modifier is released without a combo.
      -- Default: a plain, conflict-free hotkey (most reliable). Users can switch to a
      -- modifier-release or double-tap trigger from the app's "Change" sheet.
      activator = {
        kind = "hotkey",
        modifier = "rightAlt",
        onRelease = true,
        hotkey = { mods = { "ctrl" }, key = "=" },
      },
      -- Keys that exit NAV MODE.
      exitKeys = {
        { mods = {},        key = "escape" },
        { mods = { "ctrl" }, key = "c" },
      },
    },

    monitors = {
      enabled = true,
      -- Screens whose name matches this Lua pattern are treated as virtual and skipped.
      skipVirtualDisplayPattern = "16:9|HiDPI|Virtual",
      -- Off by default: the recommended NAV-MODE trigger is a Right-Option tap, so a
      -- bare Option-tap display cycle would conflict. Use nextDisplay/prevDisplay instead.
      optionTapCycle = false,  -- bare Option tap cycles to next physical screen
      optionScroll   = true,   -- Option+D / Option+U scroll half-page globally
      -- Per-screen jump bindings (Option + key). Index = physical screen left-to-right.
      jumpKeys      = { "1", "2", "3" }, -- center mouse on monitor N
      jumpClickKeys = { "0", "9", "8" }, -- center mouse on monitor N and click to focus
      parkKeys      = { "4", "5", "6" }, -- park cursor near bottom-right of monitor N
      parkPadding   = 30,
      -- Directional window/screen focus.
      focusLeft  = { mods = { "cmd", "shift" }, key = "-" },
      focusRight = { mods = { "cmd", "shift" }, key = "=" },
      -- Move the pointer to the next / previous physical display (wrap-around).
      nextDisplay = { mods = { "ctrl", "alt" }, key = "right" },
      prevDisplay = { mods = { "ctrl", "alt" }, key = "left" },
    },
  },

  -- Per-app launch/focus shortcuts (NAV MODE). Fully data-driven: add an entry to
  -- get a new shortcut. clickTarget is one of "center" | "bottom" | "none".
  apps = {
    { key = "c", mods = {},          bundleID = "com.openai.chat",          names = { "ChatGPT" },                       clickTarget = "bottom", exitNav = true },
    { key = "c", mods = { "shift" }, bundleID = "com.microsoft.VSCode",      names = { "Visual Studio Code", "Code" },    clickTarget = "center", exitNav = true },
    { key = "o", mods = {},          bundleID = "company.thebrowser.Browser", names = { "Arc" },                          clickTarget = "center", exitNav = true },
    { key = "o", mods = { "shift" }, bundleID = "com.chatgpt.atlas",         names = { "ChatGPT Atlas" },                 clickTarget = "center", exitNav = true },
    { key = "t", mods = {},          bundleID = "com.microsoft.teams2",      names = { "Microsoft Teams" },               clickTarget = "center", exitNav = true },
  },
}
