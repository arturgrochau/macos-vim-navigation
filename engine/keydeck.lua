-- KeyDeck engine bootstrap, shared by both entry points:
--   * engine/init.lua          (dedicated config — engine IS ~/.hammerspoon)
--   * spoon/KeyDeck.spoon       (coexists with the user's own init.lua)
-- The caller is responsible for putting the engine's directory on package.path
-- before calling start(); everything else lives here.
--
-- Credit: Artur Grochau – github.com/arturgrochau
local M = {}

-- Write a heartbeat the GUI polls to confirm a reload actually happened.
local function writeStatus(cfg)
  pcall(function()
    local dir = os.getenv("HOME") .. "/Library/Application Support/KeyDeck"
    hs.fs.mkdir(dir)
    local status = {
      loadedAt = os.time(),
      preset = cfg.preset or "default",
      navEnabled = (cfg.features and cfg.features.nav and cfg.features.nav.enabled) and true or false,
    }
    local f = io.open(dir .. "/engine-status.json", "w")
    if f then f:write(hs.json.encode(status)); f:close() end
  end)
end

function M.start()
  local config  = require("config")
  local Core    = require("lib.core")
  local Overlay = require("lib.overlay")

  local cfg = config.load()

  local modal = hs.hotkey.modal.new()
  local ctx = Core.new(hs, modal, cfg)
  ctx.overlay = Overlay.new(ctx)

  -- Load enabled modules. Order: nav first (owns the modal lifecycle), then the rest.
  local function enabled(name) return cfg.features[name] and cfg.features[name].enabled end

  if enabled("nav")    then require("modules.nav").setup(ctx) end
  if enabled("visual") then require("modules.visual").setup(ctx) end
  require("modules.apps").setup(ctx) -- no-ops when cfg.apps is empty
  if enabled("cursor")   then require("modules.cursor").setup(ctx) end
  if enabled("monitors") then require("modules.monitors").setup(ctx) end
  if enabled("windows")  then require("modules.windows").setup(ctx) end

  -- Optional power-user escape hatch: raw Lua appended to the engine (Developer Settings).
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
  ctx.cfg = cfg
  return ctx
end

return M
