-- Load-time harness: mock the Hammerspoon API and execute the engine so every
-- module's setup() actually runs. Catches require/runtime errors at load.
local ENGINE = arg[1]
package.path = ENGINE .. "/?.lua;" .. ENGINE .. "/?/init.lua;" .. package.path

local counts = { globalBind = 0, modalBind = 0, eventtaps = 0, alerts = {} }

-- A permissive stub: any index returns a callable that returns another stub,
-- and it is itself callable. Concrete behaviors are layered on top where needed.
local stubmt
local function stub()
  return setmetatable({}, stubmt)
end
stubmt = {
  __index = function() return function() return stub() end end,
  __call = function() return stub() end,
}

local eventtap = {
  event = setmetatable({
    types = setmetatable({}, stubmt),
    properties = setmetatable({}, stubmt),
    newMouseEvent = function() return stub() end,
    newScrollEvent = function() return stub() end,
  }, stubmt),
  new = function() counts.eventtaps = counts.eventtaps + 1; return { start = function(s) return s end } end,
  scrollWheel = function() end,
  leftClick = function() end,
  rightClick = function() end,
  keyStroke = function() end,
}

local function makeModal()
  return {
    bind = function(self) counts.modalBind = counts.modalBind + 1; return self end,
    enter = function() end,
    exit = function() end,
  }
end

hs = {
  configdir = ENGINE,
  hotkey = {
    bind = function() counts.globalBind = counts.globalBind + 1 end,
    modal = { new = makeModal },
  },
  mouse = {
    scrollDirection = function() return { natural = false } end,
    absolutePosition = function() return { x = 100, y = 100 } end,
    getCurrentScreen = function() return stub() end,
  },
  screen = setmetatable({
    allScreens = function() return {} end,
    mainScreen = function() return { frame = function() return { x = 0, y = 0, w = 1440, h = 900 } end } end,
  }, stubmt),
  eventtap = eventtap,
  window = setmetatable({}, stubmt),
  application = setmetatable({}, stubmt),
  canvas = setmetatable({ new = function() return stub() end }, stubmt),
  timer = setmetatable({
    doAfter = function() return { stop = function() end } end,
    doEvery = function() return { stop = function() end } end,
    secondsSinceEpoch = function() return 0 end,
  }, stubmt),
  fnutils = { filter = function(t) return t end },
  keycodes = { map = setmetatable({}, { __index = function() return 0 end }) },
  pathwatcher = { new = function() return { start = function(s) return s end } end },
  urlevent = { bind = function() end },
  json = { read = function() return nil end }, -- overridden per scenario
  alert = setmetatable({ show = function(m) table.insert(counts.alerts, m) end }, { __call = function(_, m) table.insert(counts.alerts, m) end }),
}

-- Make config.lua's existence check (io.open on the config path) reflect whether
-- this scenario supplies a user config, while leaving all other file IO intact.
local realopen = io.open
local currentUserConfig = nil
io.open = function(path, mode)
  if type(path) == "string" and path:match("keydeck%-config%.json") then
    if currentUserConfig == nil then return nil end
    return { close = function() end }
  end
  return realopen(path, mode)
end

local function run(label, userConfig)
  currentUserConfig = userConfig
  -- reset module cache so init/config/modules re-evaluate each scenario
  for _, m in ipairs({ "init", "config", "defaults", "lib.core", "lib.overlay",
    "modules.nav", "modules.visual", "modules.apps", "modules.cursor",
    "modules.monitors", "modules.windows" }) do
    package.loaded[m] = nil
  end
  counts.globalBind, counts.modalBind, counts.eventtaps, counts.alerts = 0, 0, 0, {}
  hs.json.read = function() return userConfig end

  local ok, err = pcall(dofile, ENGINE .. "/init.lua")
  if not ok then
    print(string.format("FAIL [%s]: %s", label, tostring(err)))
    return false
  end
  print(string.format("PASS [%s]  globalBinds=%d modalBinds=%d eventtaps=%d  alert=%q",
    label, counts.globalBind, counts.modalBind, counts.eventtaps, counts.alerts[#counts.alerts] or ""))
  return true
end

local allOk = true
-- Scenario 1: no user config (defaults: cursor/windows OFF).
allOk = run("defaults", nil) and allOk
-- Scenario 2: developer-like (all features ON).
allOk = run("all-features-on", {
  preset = "all-on",
  features = {
    cursor = { enabled = true, mods = { "alt", "cmd", "shift" }, keys = { left = "h", down = "j", up = "k", right = "l", click = "i" } },
    windows = { enabled = true, hide = { mods = { "alt", "cmd" }, key = "h" }, restore = { mods = { "alt", "shift" }, key = "r" } },
  },
}) and allOk
-- Scenario 3: minimal (visual OFF, no apps).
allOk = run("minimal", {
  preset = "minimal",
  features = { visual = { enabled = false } },
  apps = {},
}) and allOk

os.exit(allOk and 0 or 1)
