local modal = hs.hotkey.modal.new()
local heldTimers = {}

local ax = hs.axuielement
local mouse = hs.mouse
local screen = hs.screen
local eventtap = hs.eventtap
local scrollStep = 20
local mouseStep = 30

-- === OVERLAY INDICATOR ===
local overlay = hs.canvas.new({
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

-- === HELD KEYS ===
local function bindHeldKey(mod, key, fn)
  modal:bind(mod, key,
    function()
      fn()
      heldTimers[key] = hs.timer.doEvery(0.05, fn)
    end,
    function()
      if heldTimers[key] then heldTimers[key]:stop() heldTimers[key] = nil end
    end
  )
end

local function moveMouse(dx, dy)
  local pos = mouse.absolutePosition()
  mouse.absolutePosition({ x = pos.x + dx, y = pos.y + dy })
end

bindHeldKey({}, "h", function() moveMouse(-mouseStep, 0) end)
bindHeldKey({}, "l", function() moveMouse(mouseStep, 0) end)
bindHeldKey({}, "j", function() moveMouse(0, mouseStep) end)
bindHeldKey({}, "k", function() moveMouse(0, -mouseStep) end)
bindHeldKey({"shift"}, "H", function() moveMouse(-mouseStep * 4, 0) end)
bindHeldKey({"shift"}, "L", function() moveMouse(mouseStep * 4, 0) end)
bindHeldKey({"shift"}, "J", function() moveMouse(0, mouseStep * 4) end)
bindHeldKey({"shift"}, "K", function() moveMouse(0, -mouseStep * 4) end)

modal:bind({}, "i", function() eventtap.leftClick(mouse.absolutePosition()) end)
modal:bind({}, "a", function() eventtap.rightClick(mouse.absolutePosition()) end)

-- === WINDOW ELEMENTS ===
local function getWindowElements(win)
  if not win then return {} end
  local axWin = ax.windowElement(win)
  if not axWin then return {} end
  local function flatten(el)
    local out = {}
    for _, child in ipairs(el:attributeValue("AXChildren") or {}) do
      table.insert(out, child)
      for _, sub in ipairs(flatten(child)) do table.insert(out, sub) end
    end
    return out
  end
  return flatten(axWin)
end

-- === TEXTBOX LOOKUP ===
local function findTextbox(win, direction, rightmostOnly)
  local pos = mouse.absolutePosition()
  local candidates = {}
  for _, el in ipairs(getWindowElements(win)) do
    local role = el:attributeValue("AXRole")
    if role == "AXTextField" or role == "AXTextArea" then
      local f = el:attributeValue("AXFrame")
      if f then
        local cx, cy = f.x + f.w / 2, f.y + f.h / 2
        if math.abs(cy - pos.y) < 100 then
          if rightmostOnly or
            (direction == "left" and cx < pos.x) or
            (direction == "right" and cx > pos.x)
          then
            table.insert(candidates, {
              pt = { x = cx, y = cy },
              rank = rightmostOnly and -cx or math.abs(cx - pos.x)
            })
          end
        end
      end
    end
  end
  table.sort(candidates, function(a, b) return a.rank < b.rank end)
  return candidates[1] and candidates[1].pt or nil
end

-- === FOCUS + CLICK FOR SHIFT+A / SHIFT+I ===
local function shiftJump(dir)
  local cur = hs.window.focusedWindow()
  local winList = hs.window.orderedWindows()
  local target = winList[2] or winList[1]
  if target and target:id() ~= cur:id() then target:focus() end
  hs.timer.doAfter(0.2, function()
    local pt = findTextbox(hs.window.focusedWindow(), dir)
    if pt then
      mouse.absolutePosition(pt)
      eventtap.leftClick(pt)
      modal:exit()
    else
      hs.alert("No textbox found")
    end
  end)
end

modal:bind({"shift"}, "A", function() shiftJump("right") end)
modal:bind({"shift"}, "I", function() shiftJump("left") end)

-- === MOUSE TO LEFTMOST / RIGHTMOST TEXTBOX (NO CLICK) ===
local function moveToLeftmostTextbox()
  local win = hs.window.focusedWindow()
  local elements = getWindowElements(win)
  local best = nil
  for _, el in ipairs(elements) do
    local role = el:attributeValue("AXRole")
    if role == "AXTextField" or role == "AXTextArea" then
      local f = el:attributeValue("AXFrame")
      if f then
        local pt = { x = f.x, y = f.y + f.h / 2 }
        if not best or f.x < best.x then best = pt end
      end
    end
  end
  if best then mouse.absolutePosition(best) end
end

local function moveToRightmostTextbox()
  local win = hs.window.focusedWindow()
  local pt = findTextbox(win, "right", true)
  if pt then mouse.absolutePosition(pt) end
end

modal:bind({}, "0", moveToLeftmostTextbox)
modal:bind({"shift"}, "6", moveToLeftmostTextbox) -- ^
modal:bind({"shift"}, "4", moveToRightmostTextbox) -- $

-- === SCREEN EDGE ===
local function edgeJump(dx, dy)
  local f = screen.mainScreen():frame()
  mouse.absolutePosition({
    x = f.x + f.w / 2 + f.w / 2 * dx * 0.9,
    y = f.y + f.h / 2 + f.h / 2 * dy * 0.9
  })
end

modal:bind({"shift"}, "W", function() edgeJump(1, 0) end)
modal:bind({"shift"}, "B", function() edgeJump(-1, 0) end)
modal:bind({"shift"}, "U", function() edgeJump(0, -1) end)
modal:bind({"shift"}, "D", function() edgeJump(0, 1) end)

-- === MIDDLE SCREEN ===
modal:bind({"shift"}, "M", function()
  local f = screen.mainScreen():frame()
  mouse.absolutePosition({ x = f.x + f.w / 2, y = f.y + f.h / 2 })
end)

-- === SCROLLING ===
bindHeldKey({}, "d", function() eventtap.scrollWheel({0, -scrollStep}, {}, "pixel") end)
bindHeldKey({}, "u", function() eventtap.scrollWheel({0, scrollStep}, {}, "pixel") end)
bindHeldKey({}, "w", function() eventtap.scrollWheel({-scrollStep, 0}, {}, "pixel") end)
bindHeldKey({}, "b", function() eventtap.scrollWheel({scrollStep, 0}, {}, "pixel") end)

-- === NAV MODE KEYS ===
hs.hotkey.bind({"ctrl", "alt", "cmd"}, "space", function() modal:enter() end)
hs.hotkey.bind({}, "f12", function() modal:enter() end)
hs.hotkey.bind({"ctrl"}, "=", function() modal:enter() end)
modal:bind({}, "escape", function() modal:exit() end)
modal:bind({"ctrl"}, "c", function() modal:exit() end)

-- === RELOAD ===
hs.hotkey.bind({"alt"}, "r", function()
  hs.reload()
  hs.alert("Hammerspoon reloaded")
end)

-- === SCREEN JUMP (OPTION / CONTROL) ===
local function getScreens()
  local real = {}
  for _, s in ipairs(hs.screen.allScreens()) do
    if not (s:name() or ""):lower():find("virtual") then table.insert(real, s) end
  end
  return real
end

-- OPTION = center mouse on next screen
do
  local optPressed, optOtherKey = false, false
  local optIndex = 1
  hs.eventtap.new({eventtap.event.types.flagsChanged}, function(e)
    local f = e:getFlags()
    if f.alt and not optPressed then
      optPressed = true; optOtherKey = false
    elseif not f.alt and optPressed then
      optPressed = false
      if not optOtherKey then
        optIndex = (optIndex % #getScreens()) + 1
        local f = getScreens()[optIndex]:frame()
        mouse.setAbsolutePosition({ x = f.x + f.w/2, y = f.y + f.h/2 })
      end
    end
  end):start()
  hs.eventtap.new({eventtap.event.types.keyDown}, function()
    if optPressed then optOtherKey = true end
  end):start()
end

-- CONTROL = click bottom middle of next screen
do
  local ctrlPressed, ctrlOtherKey = false, false
  local ctrlIndex = 1
  hs.eventtap.new({eventtap.event.types.flagsChanged}, function(e)
    local f = e:getFlags()
    if f.ctrl and not ctrlPressed then
      ctrlPressed = true; ctrlOtherKey = false
    elseif not f.ctrl and ctrlPressed then
      ctrlPressed = false
      if not ctrlOtherKey then
        ctrlIndex = (ctrlIndex % #getScreens()) + 1
        local f = getScreens()[ctrlIndex]:frame()
        local pt = { x = f.x + f.w/2, y = f.y + f.h - 80 }
        mouse.setAbsolutePosition(pt)
        eventtap.leftClick(pt)
      end
    end
  end):start()
  hs.eventtap.new({eventtap.event.types.keyDown}, function()
    if ctrlPressed then ctrlOtherKey = true end
  end):start()
end
