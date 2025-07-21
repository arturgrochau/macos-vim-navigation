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

-- === HELD KEY FUNCTION ===
local function bindHeldKey(mod, key, fn)
  modal:bind(mod, key,
    function()
      fn()
      heldTimers[key] = hs.timer.doEvery(0.05, fn)
    end,
    function()
      if heldTimers[key] then
        heldTimers[key]:stop()
        heldTimers[key] = nil
      end
    end
  )
end

-- === MOUSE MOVEMENT ===
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

-- === CLICKING ===
modal:bind({}, "i", function() eventtap.leftClick(mouse.absolutePosition()) end)
modal:bind({}, "a", function() eventtap.rightClick(mouse.absolutePosition()) end)

-- === GET ELEMENTS ===
local function getWindowElements(win)
  if not win then return {} end
  local axWin = ax.windowElement(win)
  if not axWin then return {} end
  local function flatten(el)
    local results = {}
    local children = el:attributeValue("AXChildren") or {}
    for _, child in ipairs(children) do
      table.insert(results, child)
      for _, sub in ipairs(flatten(child)) do
        table.insert(results, sub)
      end
    end
    return results
  end
  return flatten(axWin)
end

-- === TEXTBOX SEARCH ===
local function findTextboxInWindow(win, dir)
  local pos = mouse.absolutePosition()
  local candidates = {}
  for _, el in ipairs(getWindowElements(win)) do
    local role = el:attributeValue("AXRole")
    if role == "AXTextField" or role == "AXTextArea" then
      local f = el:attributeValue("AXFrame")
      if f then
        local cx = f.x + f.w / 2
        local cy = f.y + f.h / 2
        if math.abs(cy - pos.y) < 100 then
          if (dir == "left" and cx < pos.x) or (dir == "right" and cx > pos.x) or dir == "rightmost" then
            table.insert(candidates, { pt = { x = cx, y = cy }, dist = dir == "rightmost" and -cx or math.abs(cx - pos.x) })
          end
        end
      end
    end
  end
  table.sort(candidates, function(a, b) return a.dist < b.dist end)
  return candidates[1] and candidates[1].pt or nil
end

local function tryTextboxWithFallback(dir)
  local curWin = hs.window.focusedWindow()
  local pt = findTextboxInWindow(curWin, dir)
  if pt then
    mouse.absolutePosition(pt)
    eventtap.leftClick(pt)
    modal:exit()
    return
  end

  local fallbackWin = hs.window.orderedWindows()[2]
  if fallbackWin and fallbackWin:id() ~= curWin:id() then
    fallbackWin:focus()
    hs.timer.doAfter(0.2, function()
      local pt2 = findTextboxInWindow(fallbackWin, dir)
      if pt2 then
        mouse.absolutePosition(pt2)
        eventtap.leftClick(pt2)
        modal:exit()
      else
        hs.alert("No textbox found")
      end
    end)
  else
    hs.alert("No textbox found")
  end
end

-- === LEFTMOST / RIGHTMOST ===
local function moveToLeftmost()
  local elements = getWindowElements(hs.window.focusedWindow())
  local leftmost = nil
  for _, el in ipairs(elements) do
    local f = el:attributeValue("AXFrame")
    if f and f.x then
      local pt = { x = f.x, y = f.y + f.h / 2 }
      if not leftmost or f.x < leftmost.x then
        leftmost = pt
      end
    end
  end
  if leftmost then mouse.absolutePosition(leftmost) end
end

local function moveToRightmostTextbox()
  local pt = findTextboxInWindow(hs.window.focusedWindow(), "rightmost")
  if pt then mouse.absolutePosition(pt) end
end

-- === SCREEN EDGE JUMPS ===
local function moveToDirectionEdge(dx, dy)
  local frame = screen.mainScreen():frame()
  local center = { x = frame.x + frame.w/2, y = frame.y + frame.h/2 }
  mouse.absolutePosition({
    x = center.x + (frame.w/2 * dx * 0.9),
    y = center.y + (frame.h/2 * dy * 0.9)
  })
end

-- === NAV BINDS ===
modal:bind({"shift"}, "A", function() tryTextboxWithFallback("right") end)
modal:bind({"shift"}, "I", function() tryTextboxWithFallback("left") end)
modal:bind({"shift"}, "4", moveToRightmostTextbox) -- $
modal:bind({}, "0", moveToLeftmost)
modal:bind({"shift"}, "6", moveToLeftmost) -- ^
modal:bind({"shift"}, "M", function()
  local f = screen.mainScreen():frame()
  mouse.absolutePosition({ x = f.x + f.w/2, y = f.y + f.h/2 })
end)

-- === SCROLLING (HOLDABLE) ===
bindHeldKey({}, "d", function() eventtap.scrollWheel({0, -scrollStep}, {}, "pixel") end)
bindHeldKey({}, "u", function() eventtap.scrollWheel({0, scrollStep}, {}, "pixel") end)
bindHeldKey({}, "w", function() eventtap.scrollWheel({-scrollStep, 0}, {}, "pixel") end)
bindHeldKey({}, "b", function() eventtap.scrollWheel({scrollStep, 0}, {}, "pixel") end)

-- === EDGE JUMP KEYS ===
modal:bind({"shift"}, "W", function() moveToDirectionEdge(1, 0) end)
modal:bind({"shift"}, "B", function() moveToDirectionEdge(-1, 0) end)
modal:bind({"shift"}, "U", function() moveToDirectionEdge(0, -1) end)
modal:bind({"shift"}, "D", function() moveToDirectionEdge(0, 1) end)

-- === NAV MODE TRIGGERS ===
hs.hotkey.bind({"ctrl", "alt", "cmd"}, "space", function() modal:enter() end)
hs.hotkey.bind({}, "f12", function() modal:enter() end)
hs.hotkey.bind({"ctrl"}, "=", function() modal:enter() end)
modal:bind({}, "escape", function() modal:exit() end)
modal:bind({"ctrl"}, "c", function() modal:exit() end)

-- === RELOAD HOTKEY ===
hs.hotkey.bind({"alt"}, "r", function()
  hs.reload()
  hs.alert("Hammerspoon reloaded")
end)

-- === SCREEN NAV: OPTION TAP TO MOVE TO CENTER OF NEXT SCREEN ===
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
  local scr = getScreens()[index]
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
      optionIndex = (optionIndex % #getScreens()) + 1
      centerMouseOn(optionIndex)
    end
  end
end):start()

hs.eventtap.new({eventtap.event.types.keyDown}, function()
  if optionPressed then optionOtherKey = true end
end):start()

-- === SCREEN NAV: CONTROL TAP TO CLICK NEAR BOTTOM OF NEXT SCREEN ===
local ctrlPressed, ctrlOtherKey = false, false
local ctrlIndex = 1

local function clickBottom(index)
  local scr = getScreens()[index]
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
      ctrlIndex = (ctrlIndex % #getScreens()) + 1
      clickBottom(ctrlIndex)
    end
  end
end):start()

hs.eventtap.new({eventtap.event.types.keyDown}, function()
  if ctrlPressed then ctrlOtherKey = true end
end):start()
