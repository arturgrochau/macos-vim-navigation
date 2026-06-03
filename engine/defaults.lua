-- Canonical default configuration for the navigation engine.
-- This table is the source of truth the engine falls back to when no
-- ~/.hammerspoon/keydeck-config.json is present, and it mirrors
-- config/presets/default.json (which reproduces the original main-branch behavior).
--
-- The SwiftUI preset editor writes keydeck-config.json; config.lua deep-merges it
-- over this table, so a user config only needs to specify the keys it overrides.
return {
  preset = "default",

  -- Numeric tunables shared across modules.
  tuning = {
    scrollStep             = 62,      -- pixels per scroll tick
    scrollInitialDelay     = 0.15,    -- delay before hold-to-repeat scrolling kicks in
    scrollRepeatInterval   = 0.05,    -- interval between repeated scrolls while held
    directionInitialDelay  = 0.05,    -- delay before hold-to-repeat cursor movement
    directionRepeatInterval = 0.15,   -- interval between repeated cursor moves while held
    dragMoveFrac           = 1/20,    -- fraction of screen moved per drag step in visual mode

    -- Global cursor module (option+cmd+shift+hjkl)
    globalCursorStep          = 180,  -- pixels per single tap
    globalCursorHoldStep      = 68,   -- pixels per repeat while held
    globalCursorRepeatDelay   = 0.05, -- delay before repeat starts
    globalCursorRepeatInterval = 0.02,-- interval between repeats (fast)

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
      -- Primary way to toggle NAV MODE. kind is "rightCmd" | "rightAlt" | "hotkey".
      -- rightCmd/rightAlt = tap that modifier (clean tap, guarded like the option-tap);
      -- hotkey = bind activator.hotkey as a normal toggle shortcut.
      activator = { kind = "rightCmd", hotkey = { mods = {}, key = "f12" } },
      -- Legacy fallback entry keys, used only when `activator` is absent.
      enterKeys = {
        { mods = { "ctrl", "alt", "cmd" }, key = "space" },
        { mods = {},                       key = "f12" },
        { mods = { "ctrl" },               key = "=" },
      },
      -- Keys that exit NAV MODE.
      exitKeys = {
        { mods = {},        key = "escape" },
        { mods = { "ctrl" }, key = "c" },
      },
    },

    visual = { enabled = true },

    -- Global cursor movement outside NAV MODE (off by default; on in "developer").
    cursor = {
      enabled = false,
      mods = { "alt", "cmd", "shift" },
      keys = { left = "h", down = "j", up = "k", right = "l", click = "i" },
    },

    monitors = {
      enabled = true,
      -- Screens whose name matches this Lua pattern are treated as virtual and skipped.
      skipVirtualDisplayPattern = "16:9|HiDPI|Virtual",
      optionTapCycle = true,   -- bare Option tap cycles to next physical screen
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

    -- Hide frontmost app / restore all hidden+minimized windows (off by default).
    windows = {
      enabled = false,
      hide    = { mods = { "alt", "cmd" },   key = "h" },
      restore = { mods = { "alt", "shift" }, key = "r" },
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
