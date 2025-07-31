--
-- Keyboard‑centric navigation for macOS via Hammerspoon.
--

local hs      = hs
local modal   = hs.hotkey.modal.new()
local mouse   = hs.mouse
local screen  = hs.screen
local eventtap= hs.eventtap
local window  = hs.window
local app     = hs.application
local canvas  = hs.canvas
local timer   = hs.timer

-- Scroll configuration: tiny increments on tap, smooth slow scroll on hold
local scrollStep = 62
local scrollLargeStep = scrollStep
local scrollInitialDelay = 0.15
local scrollRepeatInterval = 0.05

-- Directional repeat settings
local directionInitialDelay = 0.05
local directionRepeatInterval = 0.15

-- Timer tables
local held = {}
local holdTimers = {}
local repeatInterval = scrollRepeatInterval

-- Detect natural scrolling setting for consistent behavior
local naturalScroll = hs.mouse.scrollDirection().natural

-- Helper to normalize scroll deltas based on system setting
local function norm(delta)
  if not naturalScroll then return delta end
  return { delta[1] * -1, delta[2] * -1 }
end

-- Dragging state reserved (dragging disabled)
local dragging     = false
local dragTimer    = nil
local dragDelay    = 0.08
local dragMoveFrac = 1/20
local dragMoveLargeFrac = dragMoveFrac * 5

-- Helper: set mouse position with drag handling
local function setMousePosition(pos)
  if dragging then
    hs.eventtap.event.newMouseEvent(hs.eventtap.event.types.leftMouseDragged, pos):post()
    mouse.absolutePosition(pos)
  else
    mouse.absolutePosition(pos)
  end
end

-- Modal overlay indicator
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

-- Simple repeating keys
local function bindHeld(mod, key, fn)
  modal:bind(mod, key,
    function()
      fn()
      held[key] = timer.doEvery(repeatInterval, fn)
    end,
    function()
      if held[key] then held[key]:stop(); held[key] = nil end
    end
  )
end

-- Keys with delay before repeating
local function bindHoldWithDelay(mod, key, fn, delay, interval)
  modal:bind(mod, key,
    function()
      fn()
      holdTimers[key] = {}
      holdTimers[key].delayTimer = timer.doAfter(delay, function()
        holdTimers[key].repeatTimer = timer.doEvery(interval, fn)
      end)
    end,
    function()
      local t = holdTimers[key]
      if t then
        if t.delayTimer then t.delayTimer:stop() end
        if t.repeatTimer then t.repeatTimer:stop() end
        holdTimers[key] = nil
      end
    end
  )
end

-- Movement helper
local function moveMouseByFraction(xFrac, yFrac)
  local scr = screen.mainScreen():frame()
  local p   = mouse.absolutePosition()
  setMousePosition({ x = p.x + scr.w * xFrac, y = p.y + scr.h * yFrac })
end

-- Directional movement bindings
bindHoldWithDelay({},    "h", function() moveMouseByFraction(-1/8,  0)    end, directionInitialDelay, directionRepeatInterval)
bindHoldWithDelay({},    "l", function() moveMouseByFraction( 1/8,  0)    end, directionInitialDelay, directionRepeatInterval)
bindHoldWithDelay({},    "j", function() moveMouseByFraction( 0,     1/8) end, directionInitialDelay, directionRepeatInterval)
bindHoldWithDelay({},    "k", function() moveMouseByFraction( 0,    -1/8) end, directionInitialDelay, directionRepeatInterval)
bindHoldWithDelay({"shift"}, "H", function() moveMouseByFraction(-1/2,  0)    end, directionInitialDelay, directionRepeatInterval)
bindHoldWithDelay({"shift"}, "L", function() moveMouseByFraction( 1/2,  0)    end, directionInitialDelay, directionRepeatInterval)
bindHoldWithDelay({"shift"}, "J", function() moveMouseByFraction( 0,     1/2) end, directionInitialDelay, directionRepeatInterval)
bindHoldWithDelay({"shift"}, "K", function() moveMouseByFraction( 0,    -1/2) end, directionInitialDelay, directionRepeatInterval)

-- Scroll helper: tiny jump on tap, small repeats on hold
local function bindScrollKey(key, initialOffsets, repeatOffsets, initialDragFn, repeatDragFn)
  modal:bind({}, key,
    function()
      if dragging then
        initialDragFn()
      else
        eventtap.scrollWheel(norm(initialOffsets), {}, "pixel")
      end
      holdTimers[key] = {}
      holdTimers[key].delayTimer = timer.doAfter(scrollInitialDelay, function()
        holdTimers[key].repeatTimer = timer.doEvery(scrollRepeatInterval, function()
          if dragging then
            repeatDragFn()
          else
            eventtap.scrollWheel(norm(repeatOffsets), {}, "pixel")
          end
        end)
      end)
    end,
    function()
      local t = holdTimers[key]
      if t then
        if t.delayTimer then t.delayTimer:stop() end
        if t.repeatTimer then t.repeatTimer:stop() end
        holdTimers[key] = nil
      end
    end
  )
end

-- Scroll key bindings
bindScrollKey("d", {0, -scrollLargeStep}, {0, -scrollStep},
  function() moveMouseByFraction(0,  dragMoveLargeFrac) end,
  function() moveMouseByFraction(0,  dragMoveFrac) end)
bindScrollKey("u", {0,  scrollLargeStep}, {0,  scrollStep},
  function() moveMouseByFraction(0, -dragMoveLargeFrac) end,
  function() moveMouseByFraction(0, -dragMoveFrac) end)
bindScrollKey("w", {-scrollLargeStep, 0}, {-scrollStep, 0},
  function() moveMouseByFraction(-dragMoveLargeFrac, 0) end,
  function() moveMouseByFraction(-dragMoveFrac, 0) end)
bindScrollKey("b", { scrollLargeStep, 0}, { scrollStep, 0},
  function() moveMouseByFraction( dragMoveLargeFrac, 0) end,
  function() moveMouseByFraction( dragMoveFrac, 0) end)

-- Click bindings
modal:bind({}, "i", function()
  local pos = mouse.absolutePosition()
  local down1 = hs.eventtap.event.newMouseEvent(hs.eventtap.event.types.leftMouseDown, pos)
  down1:setProperty(hs.eventtap.event.properties.mouseEventClickState, 1)
  down1:post()
  local up1 = hs.eventtap.event.newMouseEvent(hs.eventtap.event.types.leftMouseUp, pos)
  up1:post()
  local down2 = hs.eventtap.event.newMouseEvent(hs.eventtap.event.types.leftMouseDown, pos)
  down2:setProperty(hs.eventtap.event.properties.mouseEventClickState, 2)
  down2:post()
  local up2 = hs.eventtap.event.newMouseEvent(hs.eventtap.event.types.leftMouseUp, pos)
  up2:post()
  local down3 = hs.eventtap.event.newMouseEvent(hs.eventtap.event.types.leftMouseDown, pos)
  down3:setProperty(hs.eventtap.event.properties.mouseEventClickState, 3)
  down3:post()
  local up3 = hs.eventtap.event.newMouseEvent(hs.eventtap.event.types.leftMouseUp, pos)
  up3:post()
end)
modal:bind({}, "a", function() eventtap.rightClick(mouse.absolutePosition()) end)

-- Focus cycle bindings
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

-- Scroll by a large fraction of screen height/width with hold-to-repeat
local largeScrollStep = scrollStep * 8

-- Large scroll key bindings with hold-to-repeat functionality
bindHoldWithDelay({"shift"}, "U", function()
  eventtap.scrollWheel(norm({0, largeScrollStep}), {}, "pixel")
end, scrollInitialDelay, scrollRepeatInterval)

bindHoldWithDelay({"shift"}, "D", function()
  eventtap.scrollWheel(norm({0, -largeScrollStep}), {}, "pixel")
end, scrollInitialDelay, scrollRepeatInterval)

bindHoldWithDelay({"shift"}, "W", function()
  eventtap.scrollWheel(norm({-largeScrollStep, 0}), {}, "pixel")
end, scrollInitialDelay, scrollRepeatInterval)

bindHoldWithDelay({"shift"}, "B", function()
  eventtap.scrollWheel(norm({largeScrollStep, 0}), {}, "pixel")
end, scrollInitialDelay, scrollRepeatInterval)

modal:bind({"shift"}, "M", function()
  local f = screen.mainScreen():frame()
  setMousePosition({ x = f.x + f.w/2, y = f.y + f.h/2 })
end)

-- ChatGPT shortcut bound to c
modal:bind({}, "c", function()
  local function clickChatBox(win)
    if win then
      win:raise()
      win:focus()
      local f = win:frame()
      mouse.absolutePosition({ x = f.x + f.w / 2, y = f.y + f.h - 72 })
      timer.doAfter(0.1, function()
        eventtap.leftClick(mouse.absolutePosition())
      end)
    end
  end

  local chatBundleID = "com.openai.chat"
  local runningApp = app.get("ChatGPT")
  if runningApp then
    runningApp:unhide()
    local win = runningApp:mainWindow() or window.get("ChatGPT")
    if win then
      if win:isMinimized() then win:unminimize() end
      clickChatBox(win)
    else
      local openedApp = hs.application.launchOrFocusByBundleID(chatBundleID) or hs.application.open(chatBundleID)
      if openedApp then
        timer.doAfter(1.0, function()
          local newWin = openedApp:mainWindow() or window.get("ChatGPT")
          if newWin then
            clickChatBox(newWin)
          else
            hs.alert.show("ChatGPT window could not be opened")
          end
        end)
      else
        hs.alert.show("ChatGPT app could not be launched")
      end
    end
  else
    local openedApp = hs.application.launchOrFocusByBundleID(chatBundleID) or hs.application.open(chatBundleID)
    if openedApp then
      timer.doAfter(1.0, function()
        local win = openedApp:mainWindow() or window.get("ChatGPT")
        if win then
          clickChatBox(win)
        else
          hs.alert.show("ChatGPT window did not appear")
        end
      end)
    else
      hs.alert.show("ChatGPT app could not be launched")
    end
  end
  modal:exit()
end)

-- Vim-style scroll commands: gg (double g) and G (shift+g)

local gPending = false
local gTimer   = nil
local gDoubleDelay = 0.3

local function scrollToTop()
  hs.eventtap.event.newScrollEvent(norm({0, 1000000}), {}, "pixel"):post()
end

local function scrollToBottom()
  hs.eventtap.event.newScrollEvent(norm({0, -1000000}), {}, "pixel"):post()
end

-- Double 'g' → gg → top
modal:bind({}, "g", function()
  if gPending then
    if gTimer then gTimer:stop(); gTimer = nil end
    gPending = false
    scrollToTop()
  else
    gPending = true
    gTimer = timer.doAfter(gDoubleDelay, function()
      gPending = false
      gTimer = nil
    end)
  end
end)

-- Shift+g → G → bottom
modal:bind({"shift"}, "g", function()
  gPending = false
  if gTimer then gTimer:stop(); gTimer = nil end
  scrollToBottom()
end)

-- Cancel 'g' if any other key is pressed before double-tap
local gResetTap = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(e)
  if gPending then
    local chars = e:getCharacters() or ""
    if chars:lower() ~= "g" then
      gPending = false
      if gTimer then
        gTimer:stop()
        gTimer = nil
      end
    end
  end
  return false
end)
gResetTap:start()

-- Browser shortcut bound to o
modal:bind({}, "o", function()
  local browsers = { "Arc", "Arc Browser", "Google Chrome", "Firefox", "Safari" }
  for _, name in ipairs(browsers) do
    local ok = app.launchOrFocus(name)
    if ok then return end
  end
  hs.alert.show("No known browsers found to open")
end)

-- Modal entry/exit
hs.hotkey.bind({"ctrl","alt","cmd"}, "space", function() modal:enter() end)
hs.hotkey.bind({}, "f12", function() modal:enter() end)
hs.hotkey.bind({"ctrl"}, "=", function() modal:enter() end)
modal:bind({}, "escape", function() modal:exit() end)
modal:bind({"ctrl"}, "c", function() modal:exit() end)

-- Reload config
hs.hotkey.bind({"alt"}, "r", function()
  hs.reload()
  hs.alert("Reloaded")
end)

-- Option‑tap: cycle screens and centre pointer
local optionPressed, optionOtherKey = false, false
local function centerMouseOn(scr)
  if not scr then return end
  if dragging then
    local win = window.focusedWindow()
    if win then win:moveToScreen(scr) end
  end
  local f = scr:frame()
  local pos = { x = f.x + f.w / 2, y = f.y + f.h / 2 }
  setMousePosition(pos)
end
-- Alt key flag watcher
optionFlagsWatcher = hs.eventtap.new({ hs.eventtap.event.types.flagsChanged }, function(e)
  local f = e:getFlags()
  if f.alt and not optionPressed then
    optionPressed = true
    optionOtherKey = false
  elseif not f.alt and optionPressed then
    optionPressed = false
    if not optionOtherKey then
      local currentScr = mouse.getCurrentScreen()
      local allScr = hs.screen.allScreens()
      table.sort(allScr, function(a,b) return a:frame().x < b:frame().x end)
      local currentIndex = 1
      for i, s in ipairs(allScr) do
        if s:id() == currentScr:id() then
          currentIndex = i
          break
        end
      end
      local nextIndex = (currentIndex % #allScr) + 1
      local nextScr = allScr[nextIndex]
      centerMouseOn(nextScr)
    end
  end
end)
optionFlagsWatcher:start()
-- Alt key key‑down watcher
optionKeyWatcher = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(e)
  if optionPressed then
    optionOtherKey = true
  end
  return false
end)
optionKeyWatcher:start()

-- Control‑tap: cycle screens and click near bottom
local ctrlPressed, ctrlOtherKey = false, false
local function clickBottom(scr)
  if not scr then return end
  if dragging then
    local win = window.focusedWindow()
    if win then win:moveToScreen(scr) end
  end
  local f = scr:frame()
  local pos = { x = f.x + f.w / 2, y = f.y + f.h - 80 }
  setMousePosition(pos)
  if not dragging then
    eventtap.leftClick(pos)
  end
end
-- Ctrl key flag watcher
ctrlFlagsWatcher = hs.eventtap.new({ hs.eventtap.event.types.flagsChanged }, function(e)
  local f = e:getFlags()
  if f.ctrl and not ctrlPressed then
    ctrlPressed = true
    ctrlOtherKey = false
  elseif not f.ctrl and ctrlPressed then
    ctrlPressed = false
    if not ctrlOtherKey then
      local currentScr = mouse.getCurrentScreen()
      clickBottom(currentScr)
    end
  end
end)
ctrlFlagsWatcher:start()
-- Ctrl key key‑down watcher
ctrlKeyWatcher = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(e)
  if ctrlPressed then
    ctrlOtherKey = true
  end
  return false
end)
ctrlKeyWatcher:start()

--
-- End of configuration.
--
-- Credit: Artur Grochau – github.com/arturpedrotti
