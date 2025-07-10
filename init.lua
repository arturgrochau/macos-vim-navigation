-- === Screen cycling with Option key ===
local optionPressed = false
local otherKeyPressed = false
local lastScreenIndex = 1

local function getRealScreens()
    local all = hs.screen.allScreens()
    local real = {}
    for _, screen in ipairs(all) do
        local name = screen:name() or ""
        if not name:lower():find("virtual") then
            table.insert(real, screen)
        end
    end
    return real
end

local screens = getRealScreens()
local screenCount = #screens

hs.screen.watcher.new(function()
    screens = getRealScreens()
    screenCount = #screens
end):start()

local function moveToScreen(index)
    if screenCount == 0 then return end
    local screen = screens[index]
    local frame = screen:frame()
    local center = hs.geometry.rectMidPoint(frame)
    hs.mouse.setAbsolutePosition(center)
end

local flagsWatcher = hs.eventtap.new({hs.eventtap.event.types.flagsChanged}, function(event)
    local flags = event:getFlags()
    if flags.alt and not optionPressed then
        optionPressed = true
        otherKeyPressed = false
    elseif not flags.alt and optionPressed then
        optionPressed = false
        if not otherKeyPressed then
            lastScreenIndex = (lastScreenIndex % screenCount) + 1
            moveToScreen(lastScreenIndex)
        end
    end
end)

local keyWatcher = hs.eventtap.new({hs.eventtap.event.types.keyDown}, function(event)
    if optionPressed then
        otherKeyPressed = true
    end
end)

flagsWatcher:start()
keyWatcher:start()

-- === Modal: VIM-Like Navigation ===
local modal = hs.hotkey.modal.new({"ctrl", "alt", "cmd"}, "space")

-- Optional floating overlay
local overlay = hs.canvas.new({
  x = hs.screen.mainScreen():frame().w - 140,
  y = hs.screen.mainScreen():frame().h - 40,
  h = 30,
  w = 120
})

overlay:appendElements({
  action = "fill",
  fillColor = { alpha = 0.3 },
  type = "rectangle",
  roundedRectRadii = { xRadius = 8, yRadius = 8 }
}, {
  type = "text",
  text = "NAV MODE",
  textSize = 14,
  textColor = { white = 1 },
  frame = { x = 0, y = 5, h = 30, w = 120 },
  textAlignment = "center"
})
overlay:hide()

function modal:entered()
  overlay:show()
end

function modal:exited()
  overlay:hide()
end

-- Window movement
modal:bind({}, "h", function() hs.window.focusedWindow():focusWindowWest() end)
modal:bind({}, "j", function() hs.window.focusedWindow():focusWindowSouth() end)
modal:bind({}, "k", function() hs.window.focusedWindow():focusWindowNorth() end)
modal:bind({}, "l", function() hs.window.focusedWindow():focusWindowEast() end)

-- Scroll
modal:bind({}, "d", function()
  hs.eventtap.event.newScrollEvent({0, -20}, {}, "pixel"):post()
end)

modal:bind({}, "u", function()
  hs.eventtap.event.newScrollEvent({0, 20}, {}, "pixel"):post()
end)

-- gg = scroll to top
modal:bind({}, "g", function()
  modal:bind({}, "g", function()
    hs.eventtap.event.newScrollEvent({0, 99999}, {}, "pixel"):post()
  end)
end)

-- G = scroll to bottom
modal:bind({"shift"}, "g", function()
  hs.eventtap.event.newScrollEvent({0, -99999}, {}, "pixel"):post()
end)

-- c = focus ChatGPT and click input
modal:bind({}, "c", function()
  local chatWindow = hs.window.get("ChatGPT")
  if chatWindow then
    chatWindow:focus()
    hs.timer.doAfter(0.4, function()
      local f = chatWindow:frame()
      hs.mouse.setAbsolutePosition({x = f.x + f.w / 2, y = f.y + f.h - 100})
      hs.eventtap.leftClick(hs.mouse.getAbsolutePosition())
    end)
  else
    hs.alert("ChatGPT window not found")
  end
end)

-- o = open Arc and new tab
modal:bind({}, "o", function()
  hs.application.launchOrFocus("Arc")
  hs.timer.doAfter(0.4, function()
    hs.eventtap.keyStroke({"cmd"}, "t")
  end)
end)

-- w = next tab
modal:bind({}, "w", function()
  hs.eventtap.keyStroke({"cmd", "shift"}, "]")
end)

-- b = previous tab
modal:bind({}, "b", function()
  hs.eventtap.keyStroke({"cmd", "shift"}, "[")
end)

-- Escape to exit modal
modal:bind({}, "escape", function() modal:exit() end)

-- Optional manual reload shortcut: Option + R
hs.hotkey.bind({"alt"}, "r", function()
  hs.reload()
  hs.alert("Hammerspoon reloaded")
end)