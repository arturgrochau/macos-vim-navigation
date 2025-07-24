-- Unified vim-nav-hs configuration for Hammerspoon
-- This configuration merges the duplicated sections and stores event taps
-- in variables to prevent garbage collection [oai_citation:2‡hammerspoon.org](https://www.hammerspoon.org/go/#:~:text=Lua%20uses%20Garbage%20Collection%20to,active%20your%20Lua%20code%20is).

-- Aliases for frequently used modules
local hs      = hs
local modal   = hs.hotkey.modal.new()
local mouse   = hs.mouse
local screen  = hs.screen
local eventtap= hs.eventtap
local window  = hs.window
local app     = hs.application
local canvas  = hs.canvas
local timer   = hs.timer

-- Scrolling and timers
local scrollStep = 80
local held = {}

-- Overlay used to show the modal state
local overlay = canvas.new({
  x = screen.mainScreen():frame().w - 160,
  y = screen.mainScreen():frame().h - 40,
  h = 30, w = 140
}):appendElements({
  type = "rectangle", action = "fill",
  fillColor = { alpha = 0.4, red = 0, green = 0, blue = 0 },
  roundedRectRadii = { xRadius = 8, yRadius = 8 }
}, {
  type = "text", text = "-- NORMAL --",
  textSize = 14, textColor = { white = 1 },
  frame = { x = 0, y = 5, h = 30, w = 140 },
  textAlignment = "center"
})

function modal:entered() overlay:show() end
function modal:exited()  overlay:hide() end

-- Helper to bind keys that should repeat while held
local function bindHeld(mod, key, fn)
  modal:bind(mod, key,
    function()
      fn()
      held[key] = timer.doEvery(0.05, fn)
    end,
    function()
      if held[key] then held[key]:stop(); held[key] = nil end
    end
  )
end

-- Move the mouse by a fraction of the main screen’s dimensions
local function moveMouseByFraction(xFrac, yFrac)
  local scr = screen.mainScreen():frame()
  local p   = mouse.absolutePosition()
  mouse.absolutePosition({ x = p.x + scr.w * xFrac, y = p.y + scr.h * yFrac })
end

-- Bind movement keys (nethack style)
modal:bind({},    "h", function() moveMouseByFraction(-1/8,  0   ) end)
modal:bind({},    "l", function() moveMouseByFraction( 1/8,  0   ) end)
modal:bind({},    "j", function() moveMouseByFraction( 0,     1/8) end)
modal:bind({},    "k", function() moveMouseByFraction( 0,    -1/8) end)
modal:bind({"shift"}, "H", function() moveMouseByFraction(-1/2,  0   ) end)
modal:bind({"shift"}, "L", function() moveMouseByFraction( 1/2,  0   ) end)
modal:bind({"shift"}, "J", function() moveMouseByFraction( 0,     1/2) end)
modal:bind({"shift"}, "K", function() moveMouseByFraction( 0,    -1/2) end)

-- Holdable scrolling
bindHeld({}, "d", function() eventtap.scrollWheel({0, -scrollStep}, {}, "pixel") end)
bindHeld({}, "u", function() eventtap.scrollWheel({0,  scrollStep}, {}, "pixel") end)
bindHeld({}, "w", function() eventtap.scrollWheel({-scrollStep, 0}, {}, "pixel") end)
bindHeld({}, "b", function() eventtap.scrollWheel({ scrollStep, 0}, {}, "pixel") end)

-- Clicking shortcuts
modal:bind({}, "i", function() eventtap.leftClick(mouse.absolutePosition()) end)
modal:bind({}, "a", function() eventtap.rightClick(mouse.absolutePosition()) end)

-- Cycle focus between visible windows
local function focusAppOffset(offset)
  local wins = window.visibleWindows()
  local cur  = window.focusedWindow()
  for idx, w in ipairs(wins) do
    if w:id() == cur:id() then
      local nextWin = wins[(idx + offset - 1) % #wins + 1]
      if nextWin then nextWin:focus() end
      return
    end
  end
end
modal:bind({"shift"}, "A", function() focusAppOffset( 1) end)
modal:bind({"shift"}, "I", function() focusAppOffset(-1) end)

-- Jump to screen edges and center
local function edge(dx, dy)
  local f = screen.mainScreen():frame()
  mouse.absolutePosition({ x = f.x + f.w/2 + dx * f.w * 0.45,
                           y = f.y + f.h/2 + dy * f.h * 0.45 })
end
modal:bind({"shift"}, "W", function() edge( 1, 0) end)
modal:bind({"shift"}, "B", function() edge(-1, 0) end)
modal:bind({"shift"}, "U", function() edge( 0,-1) end)
modal:bind({"shift"}, "D", function() edge( 0, 1) end)
modal:bind({"shift"}, "M", function()
  local f = screen.mainScreen():frame()
  mouse.absolutePosition({ x = f.x + f.w/2, y = f.y + f.h/2 })
end)

-- ChatGPT shortcut: focuses the ChatGPT app and clicks its chat box
modal:bind({}, "g", function()
  local function clickChatBox(win)
    if win then
      win:focus()
      local f = win:frame()
      mouse.setAbsolutePosition({ x = f.x + f.w/2, y = f.y + f.h - 72 })
      timer.doAfter(0.1, function()
        eventtap.leftClick(mouse.absolutePosition())
      end)
    end
  end
  local c = app.get("ChatGPT")
  if not c then
    app.launchOrFocus("ChatGPT")
    timer.doAfter(1.0, function()
      local win = window.get("ChatGPT")
      if win then win:focus() end
    end)
  else
    clickChatBox(window.get("ChatGPT"))
  end
  modal:exit()
end)

-- Triggers to enter/exit the modal
hs.hotkey.bind({"ctrl","alt","cmd"}, "space", function() modal:enter() end)
hs.hotkey.bind({}, "f12", function() modal:enter() end)
hs.hotkey.bind({"ctrl"}, "=", function() modal:enter() end)
modal:bind({}, "escape", function() modal:exit() end)
modal:bind({"ctrl"}, "c", function() modal:exit() end)

-- Reload configuration
hs.hotkey.bind({"alt"}, "r", function()
  hs.reload()
  hs.alert("Reloaded")
end)

-- Option‑tap: cycle through screens and center the mouse
local optionPressed, optionOtherKey, optionIndex = false, false, 1
local function centerMouseOn(index)
  local scr = screen.allScreens()[index]
  if not scr then return end
  local f = scr:frame()
  mouse.setAbsolutePosition({ x = f.x + f.w / 2, y = f.y + f.h / 2 })
end
-- Store the event taps in global variables so they aren’t garbage‑collected [oai_citation:3‡hammerspoon.org](https://www.hammerspoon.org/go/#:~:text=Lua%20uses%20Garbage%20Collection%20to,active%20your%20Lua%20code%20is)
optionFlagsWatcher = hs.eventtap.new({ eventtap.event.types.flagsChanged }, function(e)
  local f = e:getFlags()
  if f.alt and not optionPressed then
    optionPressed = true
    optionOtherKey = false
  elseif not f.alt and optionPressed then
    optionPressed = false
    if not optionOtherKey then
      optionIndex = (optionIndex % #screen.allScreens()) + 1
      centerMouseOn(optionIndex)
    end
  end
end)
optionFlagsWatcher:start()

optionKeyWatcher = hs.eventtap.new({ eventtap.event.types.keyDown }, function()
  if optionPressed then optionOtherKey = true end
end)
optionKeyWatcher:start()

-- Control‑tap: cycle through screens and click near the bottom
local ctrlPressed, ctrlOtherKey, ctrlIndex = false, false, 1
local function clickBottom(index)
  local scr = screen.allScreens()[index]
  if not scr then return end
  local f = scr:frame()
  local pos = { x = f.x + f.w / 2, y = f.y + f.h - 80 }
  mouse.setAbsolutePosition(pos)
  eventtap.leftClick(pos)
end
ctrlFlagsWatcher = hs.eventtap.new({ eventtap.event.types.flagsChanged }, function(e)
  local f = e:getFlags()
  if f.ctrl and not ctrlPressed then
    ctrlPressed = true
    ctrlOtherKey = false
  elseif not f.ctrl and ctrlPressed then
    ctrlPressed = false
    if not ctrlOtherKey then
      ctrlIndex = (ctrlIndex % #screen.allScreens()) + 1
      clickBottom(ctrlIndex)
    end
  end
end)
ctrlFlagsWatcher:start()

ctrlKeyWatcher = hs.eventtap.new({ eventtap.event.types.keyDown }, function()
  if ctrlPressed then ctrlOtherKey = true end
end)
ctrlKeyWatcher:start()
