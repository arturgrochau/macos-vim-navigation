--- === KeyDeck ===
---
--- Keyboard-centric navigation for macOS: a vim-inspired Navigation Mode
--- (pointer movement, scrolling, clicks), display switching on modifier
--- release, and app launchers — configured by the KeyDeck app or by editing
--- ~/.hammerspoon/keydeck-config.json.
---
--- Usage in ~/.hammerspoon/init.lua:
---   hs.loadSpoon("KeyDeck")
---   spoon.KeyDeck:start()
---
--- Download: https://github.com/arturgrochau/macos-vim-navigation
local obj = {}
obj.__index = obj

-- Metadata
obj.name = "KeyDeck"
obj.version = "1.0.0"
obj.author = "Artur Grochau <github.com/arturgrochau>"
obj.homepage = "https://github.com/arturgrochau/macos-vim-navigation"
obj.license = "MIT - https://opensource.org/licenses/MIT"

-- Resolve this Spoon's own directory. Prefer Hammerspoon's API; fall back to
-- the script source path (also what lets the offline test harness load us).
obj.spoonPath = (function()
  if hs and hs.spoons and hs.spoons.scriptPath then
    local ok, p = pcall(hs.spoons.scriptPath)
    if ok and type(p) == "string" and #p > 0 then return p end
  end
  return debug.getinfo(1, "S").source:sub(2):match("(.*/)")
end)()

-- Load a file from inside the Spoon. dofile (not require) so nothing is
-- registered under generic names like "config" in package.loaded, which could
-- collide with a coexisting user's own modules.
local function loadModule(rel)
  return dofile(obj.spoonPath .. rel)
end

local supportDir = os.getenv("HOME") .. "/Library/Application Support/KeyDeck"

-- Write a heartbeat the GUI polls to confirm a reload actually happened.
local function writeStatus(cfg)
  pcall(function()
    hs.fs.mkdir(supportDir)
    local status = {
      loadedAt = os.time(),
      preset = cfg.preset or "default",
      navEnabled = (cfg.features and cfg.features.nav and cfg.features.nav.enabled) and true or false,
    }
    local f = io.open(supportDir .. "/engine-status.json", "w")
    if f then f:write(hs.json.encode(status)); f:close() end
  end)
end

-- Record (or clear) the last start error for the GUI to surface.
local function writeError(message)
  pcall(function()
    local f = io.open(supportDir .. "/engine-error.txt", "w")
    if f then f:write(message or ""); f:close() end
  end)
end

--- KeyDeck:init()
--- Method
--- Called automatically by hs.loadSpoon. Nothing to set up until start().
function obj:init()
  return self
end

function obj:_start()
  local defaults = loadModule("defaults.lua")
  local config   = loadModule("config.lua")
  local Core     = loadModule("lib/core.lua")
  local Overlay  = loadModule("lib/overlay.lua")

  local cfg = config.load(defaults)

  local modal = hs.hotkey.modal.new()
  local ctx = Core.new(hs, modal, cfg)
  ctx.overlay = Overlay.new(ctx)

  -- Load enabled modules. Order: nav first (owns the modal lifecycle), then the rest.
  local function enabled(name) return cfg.features[name] and cfg.features[name].enabled end

  if enabled("nav")    then loadModule("modules/nav.lua").setup(ctx) end
  if enabled("visual") then loadModule("modules/visual.lua").setup(ctx) end
  loadModule("modules/apps.lua").setup(ctx) -- no-ops when cfg.apps is empty
  if enabled("cursor")   then loadModule("modules/cursor.lua").setup(ctx) end
  if enabled("monitors") then loadModule("modules/monitors.lua").setup(ctx) end
  if enabled("windows")  then loadModule("modules/windows.lua").setup(ctx) end

  -- Optional power-user escape hatch: raw Lua appended to the engine.
  if type(cfg.customLua) == "string" and #cfg.customLua > 0 then
    local fn, err = load(cfg.customLua, "keydeck-customLua")
    if fn then pcall(fn) elseif cfg.debug then hs.alert.show("customLua error: " .. tostring(err)) end
  end

  -- Reload binding is always available.
  hs.hotkey.bind({ "alt" }, "r", function()
    hs.reload()
    hs.alert("Reloaded")
  end)

  -- Auto-reload when keydeck-config.json changes (GUI Apply takes effect with no CLI dep).
  ctx.configWatcher = hs.pathwatcher.new(hs.configdir, function(paths)
    for _, p in ipairs(paths) do
      if p:sub(-#"keydeck-config.json") == "keydeck-config.json" then
        hs.reload()
        return
      end
    end
  end):start()

  -- Manual reload via `open -g hammerspoon://reload` (GUI fallback).
  hs.urlevent.bind("reload", function() hs.reload() end)

  writeStatus(cfg)
  if cfg.debug then hs.alert.show("KeyDeck loaded — preset: " .. (cfg.preset or "default")) end
  return ctx
end

--- KeyDeck:start()
--- Method
--- Loads the config and activates every enabled module. Never crashes the
--- user's Hammerspoon config: a start error is captured to a file the KeyDeck
--- app reads and surfaces.
function obj:start()
  local ok, res = pcall(function() return self:_start() end)
  if ok then
    self.engine = res
    writeError("") -- clear any stale error
  else
    writeError(tostring(res))
    if hs and hs.alert then hs.alert.show("KeyDeck failed to start (open the KeyDeck app for details)") end
  end
  return self
end

return obj
