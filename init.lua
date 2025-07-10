-- === VIM-STYLE NAV SYSTEM FOR macOS ===
-- Author: Artur Grochau
-- Usage: Customize keybindings and apps below to fit your workflow
-- Hammerspoon: https://www.hammerspoon.org/

local modal = hs.hotkey.modal.new()

-- === TAP OPTION TO MOVE MOUSE TO CENTER OF NEXT SCREEN ===
local optionPressed, optionOtherKey = false, false
local optionIndex = 1

local function getScreens()
  local all = hs.screen.allScreens()
  local real = {}
  for _, s in ipairs(all) do
    if not (s:name() or ""):lower():find("virtual") then table.insert(real, s) end
  end
  return real
end

local function centerMouseOn(index)
  local screen = getScreens()[index]
  if not screen then return end
  local f = screen:frame()
  hs.mouse.setAbsolutePosition({ x = f.x + f.w / 2, y = f.y + f.h / 2 })
end

hs.eventtap.new({hs.eventtap.event.types.flagsChanged}, function(e)
  local f = e:getFlags()
  if f.alt and not optionPressed then
    optionPressed = true; optionOtherKey = false
  elseif not f.alt and optionPressed then
    optionPressed = false
    if not optionOtherKey then
      local total = #getScreens()
      optionIndex = (optionIndex % total) + 1
      centerMouseOn(optionIndex)
    end
  end
end):start()

hs.eventtap.new({hs.eventtap.event.types.keyDown}, function(e)
  if optionPressed then optionOtherKey = true end
end):start()

-- === TAP CONTROL TO CLICK BOTTOM CENTER OF NEXT SCREEN ===
local ctrlPressed, ctrlOtherKey = false, false
local ctrlIndex = 1

local function clickBottom(index)
  local screen = getScreens()[index]
  if not screen then return end
  local f = screen:frame()
  local pos = { x = f.x + f.w / 2, y = f.y + f.h - 80 }
  hs.mouse.setAbsolutePosition(pos)
  hs.eventtap.leftClick(pos)
end

hs.eventtap.new({hs.eventtap.event.types.flagsChanged}, function(e)
  local f = e:getFlags()
  if f.ctrl and not ctrlPressed then
    ctrlPressed = true; ctrlOtherKey = false
  elseif not f.ctrl and ctrlPressed then
    ctrlPressed = false
    if not ctrlOtherKey then
      local total = #getScreens()
      ctrlIndex = (ctrlIndex % total) + 1
      clickBottom(ctrlIndex)
    end
  end
end):start()

hs.eventtap.new({hs.eventtap.event.types.keyDown}, function(e)
  if ctrlPressed then ctrlOtherKey = true end
end):start()

-- === TRIGGER NAV MODE ===
-- You can change or remove triggers below as desired
hs.hotkey.bind({"ctrl", "alt", "cmd"}, "space", function() modal:enter() end)
hs.hotkey.bind({}, "f12", function() modal:enter() end)
hs.hotkey.bind({"ctrl"}, "=", function() modal:enter() end)

-- === NAV MODE OVERLAY INDICATOR ===
local overlay = hs.canvas.new({
  x = hs.screen.mainScreen():frame().w - 140,
  y = hs.screen.mainScreen():frame().h - 40,
  h = 30, w = 120
}):appendElements({
  action = "fill", fillColor = { alpha = 0.3 }, type = "rectangle",
  roundedRectRadii = { xRadius = 8, yRadius = 8 }
}, {
  type = "text", text = "NAV MODE", textSize = 14,
  textColor = { white = 1 }, frame = { x = 0, y = 5, h = 30, w = 120 },
  textAlignment = "center"
})

function modal:entered() overlay:show() end
function modal:exited() overlay:hide() end

-- === NAV MODE KEYS ===
modal:bind({}, "h", function() hs.window.focusedWindow():focusWindowWest() end)
modal:bind({}, "j", function() hs.window.focusedWindow():focusWindowSouth() end)
modal:bind({}, "k", function() hs.window.focusedWindow():focusWindowNorth() end)
modal:bind({}, "l", function() hs.window.focusedWindow():focusWindowEast() end)

-- Scroll (down/up)
modal:bind({}, "d", function() hs.eventtap.scrollWheel({0, -20}, {}, "pixel") end)
modal:bind({}, "u", function() hs.eventtap.scrollWheel({0, 20}, {}, "pixel") end)

-- Scroll to top/bottom (gg/G)
local gPressedOnce = false
modal:bind({}, "g", function()
  if gPressedOnce then
    hs.eventtap.scrollWheel({0, 99999}, {}, "pixel")
    gPressedOnce = false
  else
    gPressedOnce = true
    hs.timer.doAfter(0.4, function() gPressedOnce = false end)
  end
end)
modal:bind({"shift"}, "g", function()
  hs.eventtap.scrollWheel({0, -99999}, {}, "pixel")
end)

-- c = Focus ChatGPT and click into input
modal:bind({}, "c", function()
  local win = hs.window.get("ChatGPT")
  if win then
    win:focus()
    hs.timer.doAfter(0.4, function()
      local f = win:frame()
      local pt = { x = f.x + f.w / 2, y = f.y + f.h - 100 }
      hs.mouse.setAbsolutePosition(pt)
      hs.eventtap.leftClick(pt)
    end)
  else
    hs.alert("ChatGPT window not found")
  end
  modal:exit()
end)

-- o = Open Arc and new tab
modal:bind({}, "o", function()
  hs.application.launchOrFocus("Arc")
  hs.timer.doAfter(0.4, function()
    hs.eventtap.keyStroke({"cmd"}, "t")
  end)
  modal:exit()
end)

-- a = Open/focus Arc browser (no exit)
modal:bind({}, "a", function()
  hs.application.launchOrFocus("Arc")
end)

-- v = Focus or launch VS Code and center cursor
modal:bind({}, "v", function()
  hs.application.launchOrFocus("Visual Studio Code")
  hs.timer.doAfter(0.4, function()
    local win = hs.window.focusedWindow()
    if win then
      local f = win:frame()
      hs.mouse.setAbsolutePosition({ x = f.x + f.w / 2, y = f.y + f.h / 2 })
    end
  end)
  modal:exit()
end)

-- w / b = next / previous browser tab
modal:bind({}, "w", function() hs.eventtap.keyStroke({"cmd", "shift"}, "]") end)
modal:bind({}, "b", function() hs.eventtap.keyStroke({"cmd", "shift"}, "[") end)

-- Exit NAV mode
modal:bind({}, "escape", function() modal:exit() end)
modal:bind({"ctrl"}, "c", function() modal:exit() end)

-- Manual reload
hs.hotkey.bind({"alt"}, "r", function()
  hs.reload()
  hs.alert("Hammerspoon reloaded")
end)
