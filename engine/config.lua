-- Loads the user config and deep-merges it over the defaults.
--
-- The user config lives at ~/.hammerspoon/keydeck-config.json (written by the
-- SwiftUI preset editor, or hand-edited). If it is absent or unreadable the
-- engine runs purely on defaults.lua, so a fresh install works with zero config.
local defaults = require("defaults")

local M = {}

local CONFIG_PATH = os.getenv("HOME") .. "/.hammerspoon/keydeck-config.json"

-- Deep-merge `override` onto `base`, returning a new table.
-- Maps (string keys) are merged recursively; arrays and scalars are replaced
-- wholesale so the user can, e.g., supply a complete replacement `apps` list.
local function isArray(t)
  if type(t) ~= "table" then return false end
  local n = 0
  for k in pairs(t) do
    if type(k) ~= "number" then return false end
    n = n + 1
  end
  return n > 0
end

local function deepMerge(base, override)
  if type(base) ~= "table" or type(override) ~= "table" then
    return override
  end
  if isArray(base) or isArray(override) then
    return override -- replace arrays wholesale
  end
  local out = {}
  for k, v in pairs(base) do out[k] = v end
  for k, v in pairs(override) do
    out[k] = deepMerge(out[k], v)
  end
  return out
end

-- Returns the effective config table (defaults merged with the user file).
function M.load()
  local user = nil
  local f = io.open(CONFIG_PATH, "r")
  if f then
    f:close()
    -- hs.json.read returns nil on parse error rather than throwing.
    local ok, parsed = pcall(hs.json.read, CONFIG_PATH)
    if ok and type(parsed) == "table" then
      user = parsed
    else
      hs.alert.show("keydeck-config.json is invalid; using defaults")
    end
  end

  if not user then return defaults end
  return deepMerge(defaults, user)
end

M.path = CONFIG_PATH
return M
