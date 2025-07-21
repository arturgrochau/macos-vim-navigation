local modal = hs.hotkey.modal.new()
local held = {}
local mouse = hs.mouse
local screen = hs.screen
local eventtap = hs.eventtap
local window = hs.window
local scrollStep, mouseStep = 20, 30

-- === OVERLAY ===
local overlay = hs.canvas.new({
  x = screen.mainScreen():frame().w - 160,
  y = screen.mainScreen():frame().h - 40,
  h = 30, w = 140
}):appendElements({
  type="rectangle", action="fill",
  fillColor={alpha=0.4, red=0, green=0, blue=0},
  roundedRectRadii={xRadius=8,yRadius=8}
},{
  type="text", text="-- NORMAL --",
  textSize=14, textColor={white=1},
  frame={x=0,y=5,h=30,w=140}, textAlignment="center"
})
function modal:entered() overlay:show() end
function modal:exited() overlay:hide() end

-- === HELD KEYS ===
local function bindHeld(mod, key, fn)
  modal:bind(mod, key,
    function()
      fn()
      held[key] = hs.timer.doEvery(0.05, fn)
    end,
    function()
      if held[key] then held[key]:stop(); held[key] = nil end
    end
  )
end

-- === MOUSE MOVEMENT ===
local function moveMouse(dx,dy)
  local p = mouse.absolutePosition()
  mouse.absolutePosition({x = p.x + dx, y = p.y + dy})
end
bindHeld({}, "h", function() moveMouse(-mouseStep,0) end)
bindHeld({}, "l", function() moveMouse(mouseStep,0) end)
bindHeld({}, "j", function() moveMouse(0,mouseStep) end)
bindHeld({}, "k", function() moveMouse(0,-mouseStep) end)
bindHeld({"shift"}, "H", function() moveMouse(-mouseStep*4,0) end)
bindHeld({"shift"}, "L", function() moveMouse(mouseStep*4,0) end)
bindHeld({"shift"}, "J", function() moveMouse(0,mouseStep*4) end)
bindHeld({"shift"}, "K", function() moveMouse(0,-mouseStep*4) end)

-- === CLICKING ===
modal:bind({}, "i", function() eventtap.leftClick(mouse.absolutePosition()) end)
modal:bind({}, "a", function() eventtap.rightClick(mouse.absolutePosition()) end)

-- === APP FOCUS (SHIFT+A / SHIFT+I) ===
local function focusAppOffset(offset)
  local wins = hs.window.orderedWindows()
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

-- === SCREEN EDGE + CENTER ===
local function edge(dx,dy)
  local f = screen.mainScreen():frame()
  mouse.absolutePosition({ x = f.x + f.w/2 + dx*f.w*0.45, y = f.y + f.h/2 + dy*f.h*0.45 })
end
modal:bind({"shift"},"W",function() edge(1,0) end)
modal:bind({"shift"},"B",function() edge(-1,0) end)
modal:bind({"shift"},"U",function() edge(0,-1) end)
modal:bind({"shift"},"D",function() edge(0,1) end)
modal:bind({"shift"},"M",function()
  local f = screen.mainScreen():frame()
  mouse.absolutePosition({x = f.x + f.w/2, y = f.y + f.h/2})
end)

-- === SCROLLING (HOLDABLE) ===
bindHeld({}, "d", function() eventtap.scrollWheel({0,-scrollStep},{}, "pixel") end)
bindHeld({}, "u", function() eventtap.scrollWheel({0,scrollStep},{}, "pixel") end)
bindHeld({}, "w", function() eventtap.scrollWheel({-scrollStep,0},{}, "pixel") end)
bindHeld({}, "b", function() eventtap.scrollWheel({scrollStep,0},{}, "pixel") end)

-- === NAV MODE TRIGGERS ===
hs.hotkey.bind({"ctrl","alt","cmd"}, "space", function() modal:enter() end)
hs.hotkey.bind({}, "f12", function() modal:enter() end)
hs.hotkey.bind({"ctrl"}, "=", function() modal:enter() end)
modal:bind({}, "escape", function() modal:exit() end)
modal:bind({"ctrl"}, "c", function() modal:exit() end)

-- === RELOAD CONFIG ===
hs.hotkey.bind({"alt"},"r",function()
  hs.reload()
  hs.alert("Reloaded")
end)

-- === MULTI-SCREEN SHORTCUTS (⌥ Tap and ⌃ Tap) ===
local function screenList()
  local out = {}
  for _, s in ipairs(hs.screen.allScreens()) do
    if not s:name():lower():find("virtual") then table.insert(out, s) end
  end
  return out
end

do
  local opt,other = false,false
  local idx = 1
  hs.eventtap.new({eventtap.event.types.flagsChanged}, function(e)
    local f = e:getFlags()
    if f.alt and not opt then opt,other = true,false
    elseif not f.alt and opt then opt = false
      if not other then
        idx = (idx % #screenList()) + 1
        local f = screenList()[idx]:frame()
        mouse.setAbsolutePosition({x = f.x + f.w/2, y = f.y + f.h/2})
      end
    end
  end):start()
  hs.eventtap.new({eventtap.event.types.keyDown}, function() if opt then other = true end end):start()
end

do
  local ctrl,other = false,false
  local idx = 1
  hs.eventtap.new({eventtap.event.types.flagsChanged}, function(e)
    local f = e:getFlags()
    if f.ctrl and not ctrl then ctrl,other = true,false
    elseif not f.ctrl and ctrl then ctrl = false
      if not other then
        idx = (idx % #screenList()) + 1
        local f = screenList()[idx]:frame()
        local pt = {x = f.x + f.w/2, y = f.y + f.h - 80}
        mouse.setAbsolutePosition(pt)
        eventtap.leftClick(pt)
      end
    end
  end):start()
  hs.eventtap.new({eventtap.event.types.keyDown}, function() if ctrl then other = true end end):start()
end
