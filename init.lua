local modal = hs.hotkey.modal.new()
local mouse = hs.mouse
local screen = hs.screen
local eventtap = hs.eventtap
local window = hs.window
local app = hs.application
local canvas = hs.canvas
local timer = hs.timer

local scrollStep = 80
local held = {}

-- === OVERLAY ===
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
function modal:exited() overlay:hide() end

-- === HELD SCROLL KEYS ===
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

-- === NON-HELD MOUSE MOVEMENT BASED ON SCREEN FRACTIONS ===
local function moveMouseByFraction(xFrac, yFrac)
  local scr = screen.mainScreen():frame()
  local p = mouse.absolutePosition()
  local dx, dy = scr.w * xFrac, scr.h * yFrac
  mouse.absolutePosition({ x = p.x + dx, y = p.y + dy })
end

modal:bind({}, "h", function() moveMouseByFraction(-1/8, 0) end)
modal:bind({}, "l", function() moveMouseByFraction(1/8, 0) end)
modal:bind({}, "j", function() moveMouseByFraction(0, 1/8) end)
modal:bind({}, "k", function() moveMouseByFraction(0, -1/8) end)

modal:bind({"shift"}, "H", function() moveMouseByFraction(-1/2, 0) end)
modal:bind({"shift"}, "L", function() moveMouseByFraction(1/2, 0) end)
modal:bind({"shift"}, "J", function() moveMouseByFraction(0, 1/2) end)
modal:bind({"shift"}, "K", function() moveMouseByFraction(0, -1/2) end)

-- === SCROLLING (Holdable) ===
bindHeld({}, "d", function() eventtap.scrollWheel({0, -scrollStep}, {}, "pixel") end)
bindHeld({}, "u", function() eventtap.scrollWheel({0, scrollStep}, {}, "pixel") end)
bindHeld({}, "w", function() eventtap.scrollWheel({-scrollStep, 0}, {}, "pixel") end)
bindHeld({}, "b", function() eventtap.scrollWheel({scrollStep, 0}, {}, "pixel") end)

-- === CLICKING ===
modal:bind({}, "i", function() eventtap.leftClick(mouse.absolutePosition()) end)
modal:bind({}, "a", function() eventtap.rightClick(mouse.absolutePosition()) end)

-- === FOCUS APP CYCLE ===
local function focusAppOffset(offset)
  local wins = hs.window.visibleWindows()
  local cur = hs.window.focusedWindow()
  for idx, w in ipairs(wins) do
    if w:id() == cur:id() then
      local nextWin = wins[(idx + offset - 1) % #wins + 1]
      if nextWin then nextWin:focus() end
      return
    end
  end
end

modal:bind({"shift"}, "A", function() focusAppOffset(1) end)
modal:bind({"shift"}, "I", function() focusAppOffset(-1) end)

-- === SCREEN EDGES ===
local function edge(dx, dy)
  local f = screen.mainScreen():frame()
  mouse.absolutePosition({ x = f.x + f.w/2 + dx*f.w*0.45, y = f.y + f.h/2 + dy*f.h*0.45 })
end

modal:bind({"shift"}, "W", function() edge(1,0) end)
modal:bind({"shift"}, "B", function() edge(-1,0) end)
modal:bind({"shift"}, "U", function() edge(0,-1) end)
modal:bind({"shift"}, "D", function() edge(0,1) end)
modal:bind({"shift"}, "M", function()
  local f = screen.mainScreen():frame()
  mouse.absolutePosition({ x = f.x + f.w/2, y = f.y + f.h/2 })
end)

-- === ChatGPT Shortcut ===
modal:bind({}, "g", function()
  local function clickChatBox(win)
    if win then
      win:focus()
      local f = win:frame()
      hs.mouse.setAbsolutePosition({x = f.x + f.w/2, y = f.y + f.h - 72})
      hs.timer.doAfter(0.1, function()
        hs.eventtap.leftClick(hs.mouse.absolutePosition())
      end)
    end
  end

  local c = app.get("ChatGPT")
  if not c then
    app.launchOrFocus("ChatGPT")
    hs.timer.doAfter(1.0, function()
      local win = window.get("ChatGPT")
      if win then win:focus() end
    end)
  else
    clickChatBox(window.get("ChatGPT"))
  end
  modal:exit()
end)

-- === NAV MODE TRIGGERS ===
hs.hotkey.bind({"ctrl", "alt", "cmd"}, "space", function() modal:enter() end)
hs.hotkey.bind({}, "f12", function() modal:enter() end)
hs.hotkey.bind({"ctrl"}, "=", function() modal:enter() end)
modal:bind({}, "escape", function() modal:exit() end)
modal:bind({"ctrl"}, "c", function() modal:exit() end)

-- === RELOAD CONFIG ===
hs.hotkey.bind({"alt"}, "r", function()
  hs.reload()
  hs.alert("Reloaded")
end)


-- === OPTION TAP TO CENTER MOUSE ON NEXT SCREEN ===
local optionPressed, optionOtherKey = false, false
local optionIndex = 1

local function centerMouseOn(index)
  local scr = hs.screen.allScreens()[index]
  if not scr then return end
  local f = scr:frame()
  mouse.setAbsolutePosition({ x = f.x + f.w / 2, y = f.y + f.h / 2 })
end

hs.eventtap.new({eventtap.event.types.flagsChanged}, function(e)
  local f = e:getFlags()
  if f.alt and not optionPressed then
    optionPressed = true
    optionOtherKey = false
  elseif not f.alt and optionPressed then
    optionPressed = false
    if not optionOtherKey then
      optionIndex = (optionIndex % #hs.screen.allScreens()) + 1
      centerMouseOn(optionIndex)
    end
  end
end):start()

hs.eventtap.new({eventtap.event.types.keyDown}, function()
  if optionPressed then optionOtherKey = true end
end):start()

-- === CONTROL TAP TO CLICK NEAR BOTTOM OF NEXT SCREEN ===
local ctrlPressed, ctrlOtherKey = false, false
local ctrlIndex = 1

local function clickBottom(index)
  local scr = hs.screen.allScreens()[index]
  if not scr then return end
  local f = scr:frame()
  local pos = { x = f.x + f.w / 2, y = f.y + f.h - 80 }
  mouse.setAbsolutePosition(pos)
  eventtap.leftClick(pos)
end

hs.eventtap.new({eventtap.event.types.flagsChanged}, function(e)
  local f = e:getFlags()
  if f.ctrl and not ctrlPressed then
    ctrlPressed = true
    ctrlOtherKey = false
  elseif not f.ctrl and ctrlPressed then
    ctrlPressed = false
    if not ctrlOtherKey then
      ctrlIndex = (ctrlIndex % #hs.screen.allScreens()) + 1
      clickBottom(ctrlIndex)
    end
  end
end):start()



hs.eventtap.new({eventtap.event.types.keyDown}, function()
  if ctrlPressed then ctrlOtherKey = true end
end):start()

-- vim-nav-hs
-- Original author: github.com/arturpedrotti
-- Minimal Hammerspoon navigation modal

local hs = hs
local modal = hs.hotkey.modal.new()
local mouse, screen, eventtap, window, app, canvas, timer = hs.mouse, hs.screen, hs.eventtap, hs.window, hs.application, hs.canvas, hs.timer
local held = {}
local scrollStep = 80

-- Overlay
local overlay = canvas.new({
  x = screen.mainScreen():frame().w - 160,
  y = screen.mainScreen():frame().h - 40,
  h = 30, w = 140
}):appendElements(
  { type = "rectangle", action = "fill", fillColor = { alpha = 0.4, red = 0, green = 0, blue = 0 }, roundedRectRadii = { xRadius = 8, yRadius = 8 } },
  { type = "text", text = "-- NORMAL --", textSize = 14, textColor = { white = 1 }, frame = { x = 0, y = 5, h = 30, w = 140 }, textAlignment = "center" }
)
function modal:entered() overlay:show() end
function modal:exited() overlay:hide() end

-- Held key helper
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

-- Mouse movement (screen fractions)
local function moveMouseByFraction(xFrac, yFrac)
  local scr = screen.mainScreen():frame()
  local p = mouse.absolutePosition()
  mouse.absolutePosition({ x = p.x + scr.w * xFrac, y = p.y + scr.h * yFrac })
end
modal:bind({}, "h", function() moveMouseByFraction(-1/8, 0) end)
modal:bind({}, "l", function() moveMouseByFraction(1/8, 0) end)
modal:bind({}, "j", function() moveMouseByFraction(0, 1/8) end)
modal:bind({}, "k", function() moveMouseByFraction(0, -1/8) end)
modal:bind({"shift"}, "H", function() moveMouseByFraction(-1/2, 0) end)
modal:bind({"shift"}, "L", function() moveMouseByFraction(1/2, 0) end)
modal:bind({"shift"}, "J", function() moveMouseByFraction(0, 1/2) end)
modal:bind({"shift"}, "K", function() moveMouseByFraction(0, -1/2) end)

-- Scroll (holdable)
bindHeld({}, "d", function() eventtap.scrollWheel({0, -scrollStep}, {}, "pixel") end)
bindHeld({}, "u", function() eventtap.scrollWheel({0, scrollStep}, {}, "pixel") end)
bindHeld({}, "w", function() eventtap.scrollWheel({-scrollStep, 0}, {}, "pixel") end)
bindHeld({}, "b", function() eventtap.scrollWheel({scrollStep, 0}, {}, "pixel") end)

-- Click
modal:bind({}, "i", function() eventtap.leftClick(mouse.absolutePosition()) end)
modal:bind({}, "a", function() eventtap.rightClick(mouse.absolutePosition()) end)

-- Window focus cycle
local function focusAppOffset(offset)
  local wins = window.visibleWindows()
  local cur = window.focusedWindow()
  for idx, w in ipairs(wins) do
    if w:id() == cur:id() then
      local nextWin = wins[(idx + offset - 1) % #wins + 1]
      if nextWin then nextWin:focus() end
      return
    end
  end
end
modal:bind({"shift"}, "A", function() focusAppOffset(1) end)
modal:bind({"shift"}, "I", function() focusAppOffset(-1) end)

-- Screen edges
local function edge(dx, dy)
  local f = screen.mainScreen():frame()
  mouse.absolutePosition({ x = f.x + f.w/2 + dx*f.w*0.45, y = f.y + f.h/2 + dy*f.h*0.45 })
end
modal:bind({"shift"}, "W", function() edge(1,0) end)
modal:bind({"shift"}, "B", function() edge(-1,0) end)
modal:bind({"shift"}, "U", function() edge(0,-1) end)
modal:bind({"shift"}, "D", function() edge(0,1) end)
modal:bind({"shift"}, "M", function()
  local f = screen.mainScreen():frame()
  mouse.absolutePosition({ x = f.x + f.w/2, y = f.y + f.h/2 })
end)

-- ChatGPT shortcut
modal:bind({}, "g", function()
  local function clickChatBox(win)
    if win then
      win:focus()
      local f = win:frame()
      mouse.setAbsolutePosition({x = f.x + f.w/2, y = f.y + f.h - 72})
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

-- Modal triggers
hs.hotkey.bind({"ctrl", "alt", "cmd"}, "space", function() modal:enter() end)
hs.hotkey.bind({}, "f12", function() modal:enter() end)
hs.hotkey.bind({"ctrl"}, "=", function() modal:enter() end)
modal:bind({}, "escape", function() modal:exit() end)
modal:bind({"ctrl"}, "c", function() modal:exit() end)

-- Reload
hs.hotkey.bind({"alt"}, "r", function()
  hs.reload()
  hs.alert("Reloaded")
end)

-- Option tap: center mouse on next screen
local optionPressed, optionOtherKey, optionIndex = false, false, 1
local function centerMouseOn(index)
  local scr = screen.allScreens()[index]
  if not scr then return end
  local f = scr:frame()
  mouse.setAbsolutePosition({ x = f.x + f.w / 2, y = f.y + f.h / 2 })
end
hs.eventtap.new({eventtap.event.types.flagsChanged}, function(e)
  local f = e:getFlags()
  if f.alt and not optionPressed then
    optionPressed = true; optionOtherKey = false
  elseif not f.alt and optionPressed then
    optionPressed = false
    if not optionOtherKey then
      optionIndex = (optionIndex % #screen.allScreens()) + 1
      centerMouseOn(optionIndex)
    end
  end
end):start()
hs.eventtap.new({eventtap.event.types.keyDown}, function()
  if optionPressed then optionOtherKey = true end
end):start()

-- Ctrl tap: click near bottom of next screen
local ctrlPressed, ctrlOtherKey, ctrlIndex = false, false, 1
local function clickBottom(index)
  local scr = screen.allScreens()[index]
  if not scr then return end
  local f = scr:frame()
  local pos = { x = f.x + f.w / 2, y = f.y + f.h - 80 }
  mouse.setAbsolutePosition(pos)
  eventtap.leftClick(pos)
end
hs.eventtap.new({eventtap.event.types.flagsChanged}, function(e)
  local f = e:getFlags()
  if f.ctrl and not ctrlPressed then
    ctrlPressed = true; ctrlOtherKey = false
  elseif not f.ctrl and ctrlPressed then
    ctrlPressed = false
    if not ctrlOtherKey then
      ctrlIndex = (ctrlIndex % #screen.allScreens()) + 1
      clickBottom(ctrlIndex)
    end
  end
end):start()
hs.eventtap.new({eventtap.event.types.keyDown}, function()
  if ctrlPressed then ctrlOtherKey = true end
end):start()