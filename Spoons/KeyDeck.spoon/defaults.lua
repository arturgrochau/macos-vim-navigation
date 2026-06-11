-- Canonical default configuration for the navigation engine: the source of
-- truth the engine falls back to when no ~/.hammerspoon/keydeck-config.json
-- is present. config/keydeck-config.example.json documents the same shape.
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
      -- Display switch on modifier release: tap cycleModifier alone (release it
      -- without pressing any other key) to move to the next physical screen.
      -- Guarded by tuning.optionReleaseIdleSeconds so modifier combos never
      -- trigger it. If the NAV activator taps the same modifier, the engine
      -- disables the cycle for the session.
      optionTapCycle = true,
      cycleModifier  = "alt",  -- "alt" | "ctrl" | "cmd"
      optionScroll   = true,   -- cycleModifier+D / +U scroll half-page globally
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

  -- Per-app launch/focus shortcuts (NAV MODE). Fully data-driven: add an entry
  -- to get a new shortcut. clickTarget is one of "center" | "bottom" | "none".
  -- Empty by default — the KeyDeck app detects installed apps and fills this in,
  -- or add entries to keydeck-config.json by hand (see the example config).
  apps = {},
}
