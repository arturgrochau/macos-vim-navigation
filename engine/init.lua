-- Keyboard-centric navigation for macOS via Hammerspoon — engine bootstrap.
--
-- This file is intentionally thin: it loads the effective configuration
-- (defaults deep-merged with ~/.hammerspoon/keydeck-config.json), builds the
-- shared core context, and wires up only the feature modules that are enabled.
-- All behavior lives in lib/ and modules/, and is driven by the config file the
-- SwiftUI preset editor writes. With no config file present this reproduces the
-- original main-branch behavior.
--
-- Credit: Artur Grochau – github.com/arturgrochau

-- Make `require` resolve relative to this config directory, wherever it is installed.
package.path = hs.configdir .. "/?.lua;" .. hs.configdir .. "/?/init.lua;" .. package.path

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

-- Reload binding is always available.
hs.hotkey.bind({ "alt" }, "r", function()
  hs.reload()
  hs.alert("Reloaded")
end)

hs.alert.show("KeyDeck loaded — preset: " .. (cfg.preset or "default"))
-- End of bootstrap.
