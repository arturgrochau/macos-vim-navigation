--- === KeyDeck ===
---
--- Keyboard-centric navigation for macOS (Navigation Mode, display switching, app
--- launchers), configured by the KeyDeck app. Installed alongside your own config.
---
--- Usage in ~/.hammerspoon/init.lua:
---   hs.loadSpoon("KeyDeck")
---   spoon.KeyDeck:start()
local obj = {}
obj.__index = obj
obj.name = "KeyDeck"
obj.version = "0.1.0"
obj.author = "Artur Grochau <github.com/arturgrochau>"
obj.license = "MIT"

function obj:start()
  -- This spoon bundles the engine (keydeck.lua + lib/ + modules/ + config/defaults).
  -- Put its own directory on package.path so those requires resolve here, not in
  -- the user's ~/.hammerspoon root.
  -- Resolve this spoon's own directory robustly: prefer Hammerspoon's API, fall back
  -- to the script source path.
  local dir
  if hs.spoons and hs.spoons.scriptPath then dir = hs.spoons.scriptPath() end
  if not dir or #dir == 0 then dir = debug.getinfo(1, "S").source:sub(2):match("(.*/)") end
  if dir and not dir:match("/$") then dir = dir:match("(.*/)") or dir end
  package.path = dir .. "?.lua;" .. dir .. "?/init.lua;" .. package.path
  -- Never crash the user's config silently: capture any load error to a file the app reads.
  local ok, res = pcall(function() return require("keydeck").start() end)
  if ok then
    self.engine = res
    local ef = io.open(os.getenv("HOME") .. "/Library/Application Support/KeyDeck/engine-error.txt", "w")
    if ef then ef:write(""); ef:close() end  -- clear any stale error
  else
    local f = io.open(os.getenv("HOME") .. "/Library/Application Support/KeyDeck/engine-error.txt", "w")
    if f then f:write(tostring(res)); f:close() end
    if hs and hs.alert then hs.alert.show("KeyDeck failed to start (see Account → Developer)") end
  end
  return self
end

return obj
