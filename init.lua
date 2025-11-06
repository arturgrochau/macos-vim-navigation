-- Keyboard-centric navigation for macOS via Hammerspoon.
local hs = hs
local modal = hs.hotkey.modal.new()
local mouse = hs.mouse
local screen = hs.screen
local eventtap = hs.eventtap
local window = hs.window
local app = hs.application
local canvas = hs.canvas
local timer = hs.timer
-- Scroll configuration
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
-- Natural scrolling
local naturalScroll = hs.mouse.scrollDirection().natural
local function norm(delta)
  if not naturalScroll then return delta end
  return { delta[1] * -1, delta[2] * -1 }
end
-- Dragging state
local dragging = false
local dragMoveFrac = 1/20
local dragMoveLargeFrac = dragMoveFrac * 5
-- Mode state
local mode = "normal"
local function setMousePosition(pos)
  if dragging then
    eventtap.event.newMouseEvent(eventtap.event.types.leftMouseDragged, pos):post()
  end
  mouse.absolutePosition(pos)
end
-- Overlay
local overlay = nil
local function createOverlay()
  if overlay then overlay:delete() end
  local currentScr = mouse.getCurrentScreen():frame()
  overlay = canvas.new({
    x = currentScr.x + currentScr.w - 210,
    y = currentScr.y + currentScr.h - 130,
    h = 30, w = 200
  }):appendElements({
    type = "rectangle", action = "fill",
    fillColor = { alpha = 0.4, red = 0, green = 0, blue = 0 },
    roundedRectRadii = { xRadius = 8, yRadius = 8 }
  }, {
    id = "modeText",
    type = "text", text = "-- NORMAL --",
    textSize = 14, textColor = { white = 1 },
    frame = { x = 0, y = 5, h = 30, w = 200 },
    textAlignment = "center"
  })
end
local visualIndicator = nil
local function showVisualIndicator()
  if visualIndicator then return end
  local currentScr = mouse.getCurrentScreen():frame()
  visualIndicator = canvas.new({
    x = currentScr.x + currentScr.w - 210,
    y = currentScr.y + currentScr.h - 90,
    w = 200, h = 30
  }):appendElements({
    type = "rectangle", action = "fill",
    fillColor = { red = 0.2, green = 0.2, blue = 1, alpha = 0.5 },
    roundedRectRadii = { xRadius = 8, yRadius = 8 }
  }, {
    type = "text", text = "-- VISUAL MODE --",
    textSize = 14, textColor = { white = 1 },
    frame = { x = 0, y = 5, h = 30, w = 200 },
    textAlignment = "center"
  })
  visualIndicator:show()
end
local function hideVisualIndicator()
  if visualIndicator then
    visualIndicator:delete()
    visualIndicator = nil
  end
end
function modal:entered()
  createOverlay()
  overlay:show()
end
function modal:exited()
  if overlay then overlay:hide() end
  if mode == "visual" then
    local pos = mouse.absolutePosition()
    if dragging then
      eventtap.event.newMouseEvent(eventtap.event.types.leftMouseUp, pos):post()
      dragging = false
    end
    timer.doAfter(0.05, function() eventtap.leftClick(pos) end)
    mode = "normal"
    hideVisualIndicator()
  end
end
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
local function moveMouseByFraction(xFrac, yFrac)
  local scr = screen.mainScreen():frame()
  local p = mouse.absolutePosition()
  if mode == "visual" and not dragging then
    dragging = true
    eventtap.event.newMouseEvent(eventtap.event.types.leftMouseDown, p):post()
  end
  setMousePosition({ x = p.x + scr.w * xFrac, y = p.y + scr.h * yFrac })
end
-- Directional movements
local directions = {
  {mod = {}, key = "h", frac = 1/8, dx = -1, dy = 0},
  {mod = {}, key = "l", frac = 1/8, dx = 1, dy = 0},
  {mod = {}, key = "j", frac = 1/8, dx = 0, dy = 1},
  {mod = {}, key = "k", frac = 1/8, dx = 0, dy = -1},
  {mod = {"shift"}, key = "h", frac = 1/2, dx = -1, dy = 0},
  {mod = {"shift"}, key = "l", frac = 1/2, dx = 1, dy = 0},
  {mod = {"shift"}, key = "j", frac = 1/2, dx = 0, dy = 1},
  {mod = {"shift"}, key = "k", frac = 1/2, dx = 0, dy = -1},
}
for _, dir in ipairs(directions) do
  local xFrac, yFrac = dir.dx * dir.frac, dir.dy * dir.frac
  bindHoldWithDelay(dir.mod, dir.key, function() moveMouseByFraction(xFrac, yFrac) end, directionInitialDelay, directionRepeatInterval)
end
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
-- Scroll bindings
bindScrollKey("d", {0, -scrollLargeStep}, {0, -scrollStep},
  function() moveMouseByFraction(0, dragMoveLargeFrac) end,
  function() moveMouseByFraction(0, dragMoveFrac) end)
bindScrollKey("u", {0, scrollLargeStep}, {0, scrollStep},
  function() moveMouseByFraction(0, -dragMoveLargeFrac) end,
  function() moveMouseByFraction(0, -dragMoveFrac) end)
bindScrollKey("w", {-scrollLargeStep, 0}, {-scrollStep, 0},
  function() moveMouseByFraction(mode == "visual" and dragMoveLargeFrac or -dragMoveLargeFrac, 0) end,
  function() moveMouseByFraction(mode == "visual" and dragMoveFrac or -dragMoveFrac, 0) end)
bindScrollKey("b", { scrollLargeStep, 0}, { scrollStep, 0},
  function() moveMouseByFraction(mode == "visual" and -dragMoveLargeFrac or dragMoveLargeFrac, 0) end,
  function() moveMouseByFraction(mode == "visual" and -dragMoveFrac or dragMoveFrac, 0) end)
-- Arrow key bindings: up/down for scrolling (like u/d), left/right for cursor movement (like h/l)
bindScrollKey("down", {0, -scrollLargeStep}, {0, -scrollStep},
  function() moveMouseByFraction(0, dragMoveLargeFrac) end,
  function() moveMouseByFraction(0, dragMoveFrac) end)
bindScrollKey("up", {0, scrollLargeStep}, {0, scrollStep},
  function() moveMouseByFraction(0, -dragMoveLargeFrac) end,
  function() moveMouseByFraction(0, -dragMoveFrac) end)
-- Left/right arrows: move cursor horizontally (same as h/l keys)
local arrowDirections = {
  {key = "left", frac = 1/8, dx = -1, dy = 0},
  {key = "right", frac = 1/8, dx = 1, dy = 0},
}
for _, dir in ipairs(arrowDirections) do
  local xFrac, yFrac = dir.dx * dir.frac, dir.dy * dir.frac
  bindHoldWithDelay({}, dir.key, function() moveMouseByFraction(xFrac, yFrac) end, directionInitialDelay, directionRepeatInterval)
end
local largeScrollStep = scrollStep * 8
local largeScrolls = {
  {mod = {"shift"}, key = "u", delta = {0, largeScrollStep}},
  {mod = {"shift"}, key = "d", delta = {0, -largeScrollStep}},
  {mod = {"shift"}, key = "w", delta = {-largeScrollStep, 0}},
  {mod = {"shift"}, key = "b", delta = {largeScrollStep, 0}},
}
for _, sc in ipairs(largeScrolls) do
  bindHoldWithDelay(sc.mod, sc.key, function()
    eventtap.scrollWheel(norm(sc.delta), {}, "pixel")
  end, scrollInitialDelay, scrollRepeatInterval)
end
-- Medium scroll bindings (Ctrl+U/D) - between normal and large scroll
local mediumScrollStep = scrollStep * 3
local mediumScrolls = {
  {mod = {"ctrl"}, key = "u", delta = {0, mediumScrollStep}},
  {mod = {"ctrl"}, key = "d", delta = {0, -mediumScrollStep}},
}
for _, sc in ipairs(mediumScrolls) do
  bindHoldWithDelay(sc.mod, sc.key, function()
    eventtap.scrollWheel(norm(sc.delta), {}, "pixel")
  end, scrollInitialDelay, scrollRepeatInterval)
end
local function performClicks(count, keepLastDown)
  local pos = mouse.absolutePosition()
  for i = 1, count do
    local down = eventtap.event.newMouseEvent(eventtap.event.types.leftMouseDown, pos)
    down:setProperty(eventtap.event.properties.mouseEventClickState, i)
    down:post()
    if i < count or not keepLastDown then
      local up = eventtap.event.newMouseEvent(eventtap.event.types.leftMouseUp, pos)
      up:post()
    end
  end
end
local function endDragAndClick(pos, action)
  if dragging then
    eventtap.event.newMouseEvent(eventtap.event.types.leftMouseUp, pos):post()
    dragging = false
  end
  if action then
    timer.doAfter(0.05, function()
      eventtap.keyStroke({"cmd"}, action)
      timer.doAfter(0.05, function() eventtap.leftClick(pos) end)
    end)
  else
    timer.doAfter(0.05, function() eventtap.leftClick(pos) end)
  end
end
-- Click bindings
modal:bind({}, "i", function() performClicks(3, false) end)
modal:bind({}, "a", function() eventtap.rightClick(mouse.absolutePosition()) end)
-- Visual mode bindings
modal:bind({}, "v", function()
  local pos = mouse.absolutePosition()
  if mode == "visual" then
    endDragAndClick(pos)
    dragging = false
    mode = "normal"
    hideVisualIndicator()
  else
    dragging = true
    eventtap.event.newMouseEvent(eventtap.event.types.leftMouseDown, pos):post()
    mode = "visual"
    showVisualIndicator()
  end
end)
modal:bind({"shift"}, "v", function()
  local pos = mouse.absolutePosition()
  if mode == "visual" then
    endDragAndClick(pos)
    dragging = false
    mode = "normal"
    hideVisualIndicator()
  else
    performClicks(3, true)
    dragging = true
    mode = "visual"
    showVisualIndicator()
  end
end)
modal:bind({}, "y", function()
  if mode == "visual" and dragging then
    endDragAndClick(mouse.absolutePosition(), "c")
    mode = "normal"
    hideVisualIndicator()
  else
    -- Copy selected text or current line when not in visual mode
    hs.eventtap.keyStroke({"cmd"}, "c")
  end
end)
modal:bind({}, "p", function()
  if mode == "visual" and dragging then
    endDragAndClick(mouse.absolutePosition(), "v")
    mode = "normal"
    hideVisualIndicator()
  else
    local pos = mouse.absolutePosition()
    eventtap.leftClick(pos)
    timer.doAfter(0.05, function()
      eventtap.keyStroke({"cmd"}, "v")
      timer.doAfter(0.05, function() modal:exit() end)
    end)
  end
end)
modal:bind({"shift"}, "p", function()
  if mode == "visual" and dragging then
    endDragAndClick(mouse.absolutePosition(), "v")
    mode = "normal"
    hideVisualIndicator()
  else
    local pos = mouse.absolutePosition()
    eventtap.leftClick(pos)
    timer.doAfter(0.05, function()
      eventtap.keyStroke({"cmd"}, "v")
      timer.doAfter(0.05, function() modal:exit() end)
    end)
  end
end)
-- Focus cycle
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
modal:bind({"shift"}, "a", function() focusAppOffset(1) end)
modal:bind({"shift"}, "i", function() focusAppOffset(-1) end)
modal:bind({"shift"}, "m", function()
  local f = screen.mainScreen():frame()
  setMousePosition({ x = f.x + f.w/2, y = f.y + f.h/2 })
end)
-- ChatGPT shortcut
modal:bind({}, "c", function()
  if mode == "visual" then
    local pos = mouse.absolutePosition()
    if dragging then
      eventtap.event.newMouseEvent(eventtap.event.types.leftMouseUp, pos):post()
      dragging = false
    end
    timer.doAfter(0.05, function() eventtap.leftClick(pos) end)
    mode = "normal"
    hideVisualIndicator()
  end
  local function clickChatBox(win)
    if win then
      win:raise()
      win:focus()
      local f = win:frame()
      mouse.absolutePosition({ x = f.x + f.w / 2, y = f.y + f.h - 72 })
      timer.doAfter(0.2, function() eventtap.leftClick(mouse.absolutePosition()) end)
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
        timer.doAfter(2.0, function()
          local newWin = openedApp:mainWindow() or window.get("ChatGPT")
          if newWin then clickChatBox(newWin) else hs.alert.show("ChatGPT window could not be opened") end
        end)
      else
        hs.alert.show("ChatGPT app could not be launched")
      end
    end
  else
    local openedApp = hs.application.launchOrFocusByBundleID(chatBundleID) or hs.application.open(chatBundleID)
    if openedApp then
      timer.doAfter(2.0, function()
        local win = openedApp:mainWindow() or window.get("ChatGPT")
        if win then clickChatBox(win) else hs.alert.show("ChatGPT window did not appear") end
      end)
    else
      hs.alert.show("ChatGPT app could not be launched")
    end
  end
  modal:exit()
end)
-- VSCode shortcut (uppercase C)
modal:bind({"shift"}, "c", function()
  if mode == "visual" then
    local pos = mouse.absolutePosition()
    if dragging then
      eventtap.event.newMouseEvent(eventtap.event.types.leftMouseUp, pos):post()
      dragging = false
    end
    timer.doAfter(0.05, function() eventtap.leftClick(pos) end)
    mode = "normal"
    hideVisualIndicator()
  end
 
  local vscodeBundleID = "com.microsoft.VSCode"
  local vscodeAppNames = {"Visual Studio Code", "Code"}  -- Support standard VSCode and possible alternatives like Insiders
 
  local function clickEditorArea(win)
    if win then
      win:raise()
      win:focus()
      local f = win:frame()
      mouse.absolutePosition({ x = f.x + f.w / 2, y = f.y + f.h / 2 })
      timer.doAfter(0.2, function() eventtap.leftClick(mouse.absolutePosition()) end)
    end
  end
 
  local runningApp = nil
  for _, name in ipairs(vscodeAppNames) do
    runningApp = app.get(name)
    if runningApp then break end
  end
 
  if runningApp then
    runningApp:unhide()
    local win = runningApp:mainWindow()
    if win then
      if win:isMinimized() then win:unminimize() end
      clickEditorArea(win)
    else
      local openedApp = hs.application.launchOrFocusByBundleID(vscodeBundleID) or hs.application.open(vscodeBundleID)
      if openedApp then
        timer.doAfter(2.0, function()
          local newWin = openedApp:mainWindow()
          if newWin then
            clickEditorArea(newWin)
          else
            hs.alert.show("VSCode window could not be opened")
          end
        end)
      else
        hs.alert.show("VSCode could not be launched")
      end
    end
  else
    local openedApp = hs.application.launchOrFocusByBundleID(vscodeBundleID) or hs.application.open(vscodeBundleID)
    if openedApp then
      timer.doAfter(2.0, function()
        local win = openedApp:mainWindow()
        if win then
          clickEditorArea(win)
        else
          hs.alert.show("VSCode window did not appear")
        end
      end)
    else
      hs.alert.show("VSCode could not be launched")
    end
  end
  modal:exit()
end)
-- Vim-style scroll
local gPending = false
local gTimer = nil
local gDoubleDelay = 0.3
local function scrollToTop()
  eventtap.event.newScrollEvent(norm({0, 1000000}), {}, "pixel"):post()
end
local function scrollToBottom()
  eventtap.event.newScrollEvent(norm({0, -1000000}), {}, "pixel"):post()
end
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
modal:bind({"shift"}, "g", function()
  gPending = false
  if gTimer then gTimer:stop(); gTimer = nil end
  scrollToBottom()
end)
local gResetTap = eventtap.new({ eventtap.event.types.keyDown }, function(e)
  if gPending then
    local chars = e:getCharacters() or ""
    if chars:lower() ~= "g" then
      gPending = false
      if gTimer then gTimer:stop(); gTimer = nil end
    end
  end
  return false
end)
gResetTap:start()
-- Browser shortcut (specific to Arc)
modal:bind({}, "o", function()
  local arcBundleID = "company.thebrowser.Browser"
  local arcAppName = "Arc"

  local function clickCenter(win)
    if win then
      win:raise()
      win:focus()
      local f = win:frame()
      mouse.absolutePosition({ x = f.x + f.w / 2, y = f.y + f.h / 2 })
      timer.doAfter(0.2, function() eventtap.leftClick(mouse.absolutePosition()) end)
    end
  end

  local runningApp = app.get(arcAppName)
  if runningApp then
    runningApp:unhide()
    local win = runningApp:mainWindow()
    if win then
      if win:isMinimized() then win:unminimize() end
      clickCenter(win)
    else
      local openedApp = hs.application.launchOrFocusByBundleID(arcBundleID) or hs.application.open(arcBundleID)
      if openedApp then
        timer.doAfter(2.0, function()
          local newWin = openedApp:mainWindow()
          if newWin then
            clickCenter(newWin)
          else
            hs.alert.show("Arc window could not be opened")
          end
        end)
      else
        hs.alert.show("Arc could not be launched")
      end
    end
  else
    local openedApp = hs.application.launchOrFocusByBundleID(arcBundleID) or hs.application.open(arcBundleID)
    if openedApp then
      timer.doAfter(2.0, function()
        local win = openedApp:mainWindow()
        if win then
          clickCenter(win)
        else
          hs.alert.show("Arc window did not appear")
        end
      end)
    else
      hs.alert.show("Arc could not be launched")
    end
  end
  modal:exit()
end)

-- ChatGPT Atlas browser shortcut (Shift + O)
modal:bind({"shift"}, "o", function()
  local atlasBundleID = "com.chatgpt.atlas"
  local atlasAppName = "ChatGPT Atlas"

  local function clickCenter(win)
    if win then
      win:raise()
      win:focus()
      local f = win:frame()
      mouse.absolutePosition({ x = f.x + f.w / 2, y = f.y + f.h / 2 })
      timer.doAfter(0.2, function() eventtap.leftClick(mouse.absolutePosition()) end)
    end
  end

  local runningApp = app.get(atlasAppName)
  if runningApp then
    runningApp:unhide()
    local win = runningApp:mainWindow()
    if win then
      if win:isMinimized() then win:unminimize() end
      timer.doAfter(0.1, function() clickCenter(win) end)
    else
      local openedApp = hs.application.launchOrFocusByBundleID(atlasBundleID) or hs.application.open(atlasAppName)
      if openedApp then
        timer.doAfter(2.0, function()
          local newWin = openedApp:mainWindow()
          if newWin then
            clickCenter(newWin)
          else
            hs.alert.show("ChatGPT Atlas window could not be opened")
          end
        end)
      else
        hs.alert.show("ChatGPT Atlas could not be launched")
      end
    end
  else
    local openedApp = hs.application.launchOrFocusByBundleID(atlasBundleID) or hs.application.open(atlasAppName)
    if openedApp then
      timer.doAfter(2.0, function()
        local win = openedApp:mainWindow()
        if win then
          clickCenter(win)
        else
          hs.alert.show("ChatGPT Atlas window did not appear")
        end
      end)
    else
      hs.alert.show("ChatGPT Atlas could not be launched")
    end
  end
  modal:exit()
end)

-- Microsoft Teams shortcut
modal:bind({}, "t", function()
  local teamsBundleID = "com.microsoft.teams2"
  local teamsAppName = "Microsoft Teams"

  local function clickCenter(win)
    if win then
      win:raise()
      win:focus()
      local f = win:frame()
      mouse.absolutePosition({ x = f.x + f.w / 2, y = f.y + f.h / 2 })
      timer.doAfter(0.2, function() eventtap.leftClick(mouse.absolutePosition()) end)
    end
  end

  local runningApp = app.get(teamsAppName)
  if runningApp then
    runningApp:unhide()
    local win = runningApp:mainWindow()
    if win then
      if win:isMinimized() then win:unminimize() end
      clickCenter(win)
    else
      local openedApp = hs.application.launchOrFocusByBundleID(teamsBundleID) or hs.application.open(teamsAppName)
      if openedApp then
        timer.doAfter(2.0, function()
          local newWin = openedApp:mainWindow()
          if newWin then
            clickCenter(newWin)
          else
            hs.alert.show("Teams window could not be opened")
          end
        end)
      else
        hs.alert.show("Teams could not be launched")
      end
    end
  else
    local openedApp = hs.application.launchOrFocusByBundleID(teamsBundleID) or hs.application.open(teamsAppName)
    if openedApp then
      timer.doAfter(2.0, function()
        local win = openedApp:mainWindow()
        if win then
          clickCenter(win)
        else
          hs.alert.show("Teams window did not appear")
        end
      end)
    else
      hs.alert.show("Teams could not be launched")
    end
  end
  modal:exit()
end)


-- Modal entry/exit
hs.hotkey.bind({"ctrl","alt","cmd"}, "space", function() modal:enter() end)
hs.hotkey.bind({}, "f12", function() modal:enter() end)
hs.hotkey.bind({"ctrl"}, "=", function() modal:enter() end)
modal:bind({}, "escape", function() modal:exit() end)
modal:bind({"ctrl"}, "c", function() modal:exit() end)

---------------------------------------------------------------------------
-- Seamless Window Minimize / Restore (Cmd+Shift+M / Cmd+Shift+R)
---------------------------------------------------------------------------
local minimizeStack = {}

-- Push unique windows (avoid duplicates)
local function pushUnique(stack, win)
  if not win then return end
  for i = #stack, 1, -1 do
    if stack[i]:id() == win:id() then
      table.remove(stack, i)
      break
    end
  end
  table.insert(stack, win)
end

-- Minimize and focus next available window
local function minimizeFocused()
  local win = hs.window.focusedWindow()
  if not win then
    hs.alert.show("No active window to minimize")
    return
  end

  local appName = win:application():name() or "Unknown"
  pushUnique(minimizeStack, win)
  win:minimize()

  -- Try to focus the next window (from the same app first, then any)
  local allWins = hs.window.orderedWindows()
  for _, w in ipairs(allWins) do
    if w:id() ~= win:id() and not w:isMinimized() then
      w:focus()
      hs.alert.show("Minimized: " .. appName)
      return
    end
  end
  hs.alert.show("Minimized: " .. appName .. " (no other window to focus)")
end

-- Try restoring the last minimized, or fallback to any minimized
local function findAnyMinimized()
  local all = hs.window.allWindows()
  for i = #all, 1, -1 do
    if all[i]:isMinimized() then return all[i] end
  end
  return nil
end

local function restoreLast()
  local win = table.remove(minimizeStack)
  if not (win and win:isMinimized()) then
    win = findAnyMinimized()
  end
  if win then
    win:unminimize()
    win:focus()
    hs.alert.show("Restored: " .. (win:application():name() or "Unknown"))
  else
    hs.alert.show("No minimized windows to restore")
  end
end

-- Cmd + Shift + M: Minimize the focused window
hs.hotkey.bind({"cmd", "shift"}, "m", minimizeFocused)

-- Cmd + Shift + R: Restore the most recently minimized window
hs.hotkey.bind({"cmd", "shift"}, "r", restoreLast)

---------------------------------------------------------------------------
-- Window Focus Navigation (Cmd+Shift+- / Cmd+Shift+=)
-- Switches focus between visible windows on different monitors or cycles on same screen
---------------------------------------------------------------------------

local function focusWindowInDirection(direction)
  local currentWin = hs.window.focusedWindow()
  if not currentWin then
    hs.alert.show("No window focused")
    return
  end

  local currentScreen = currentWin:screen()
  local allScreens = hs.screen.allScreens()
  
  -- Get all visible, non-minimized windows
  local visibleWindows = hs.fnutils.filter(hs.window.orderedWindows(), function(w)
    return not w:isMinimized() and w:isVisible() and w:isStandard()
  end)
  
  if #visibleWindows <= 1 then
    hs.alert.show("No other visible windows")
    return
  end

  -- Multi-monitor setup: switch between screens
  if #allScreens > 1 then
    -- Sort screens by position (left to right)
    table.sort(allScreens, function(a, b) return a:frame().x < b:frame().x end)
    
    -- Find current screen index
    local currentScreenIndex = 1
    for i, scr in ipairs(allScreens) do
      if scr:id() == currentScreen:id() then
        currentScreenIndex = i
        break
      end
    end
    
    local targetScreen = nil
    
    if direction == "left" then
      -- Move to screen on the left
      if currentScreenIndex > 1 then
        targetScreen = allScreens[currentScreenIndex - 1]
      else
        -- Wrap around to rightmost screen
        targetScreen = allScreens[#allScreens]
      end
    elseif direction == "right" then
      -- Move to screen on the right
      if currentScreenIndex < #allScreens then
        targetScreen = allScreens[currentScreenIndex + 1]
      else
        -- Wrap around to leftmost screen
        targetScreen = allScreens[1]
      end
    end
    
    -- Find the most recently used visible window on the target screen
    local targetWindow = nil
    for _, w in ipairs(visibleWindows) do
      if w:screen():id() == targetScreen:id() and w:id() ~= currentWin:id() then
        targetWindow = w
        break  -- orderedWindows() gives us most recent first
      end
    end
    
    if targetWindow then
      targetWindow:focus()
      hs.alert.show("Focused: " .. (targetWindow:application():name() or "Window"))
    else
      -- No window on target screen, just move mouse there
      local f = targetScreen:frame()
      hs.mouse.absolutePosition({ x = f.x + f.w / 2, y = f.y + f.h / 2 })
      hs.alert.show("No window on " .. (direction == "left" and "left" or "right") .. " screen")
    end
  else
    -- Single monitor: cycle through windows by horizontal position
    local currentFrame = currentWin:frame()
    local currentX = currentFrame.x + currentFrame.w / 2
    
    -- Get windows on current screen sorted by position
    local screenWindows = {}
    for _, w in ipairs(visibleWindows) do
      if w:screen():id() == currentScreen:id() and w:id() ~= currentWin:id() then
        local f = w:frame()
        table.insert(screenWindows, {
          window = w,
          x = f.x + f.w / 2
        })
      end
    end
    
    if #screenWindows == 0 then
      hs.alert.show("No other windows on screen")
      return
    end
    
    -- Sort by x position
    table.sort(screenWindows, function(a, b) return a.x < b.x end)
    
    local targetWindow = nil
    
    if direction == "left" then
      -- Find closest window to the left
      for i = #screenWindows, 1, -1 do
        if screenWindows[i].x < currentX then
          targetWindow = screenWindows[i].window
          break
        end
      end
      -- If none found, wrap to rightmost
      if not targetWindow then
        targetWindow = screenWindows[#screenWindows].window
      end
    elseif direction == "right" then
      -- Find closest window to the right
      for i = 1, #screenWindows do
        if screenWindows[i].x > currentX then
          targetWindow = screenWindows[i].window
          break
        end
      end
      -- If none found, wrap to leftmost
      if not targetWindow then
        targetWindow = screenWindows[1].window
      end
    end
    
    if targetWindow then
      targetWindow:focus()
      hs.alert.show("Focused: " .. (targetWindow:application():name() or "Window"))
    end
  end
end

-- Keybindings: Cmd+Shift+- (left) and Cmd+Shift+= (right)
hs.hotkey.bind({"cmd", "shift"}, "-", function() focusWindowInDirection("left") end)
hs.hotkey.bind({"cmd", "shift"}, "=", function() focusWindowInDirection("right") end)

-- Reload config
hs.hotkey.bind({"alt"}, "r", function()
  hs.reload()
  hs.alert("Reloaded")
end)

-- Option-tap: cycle screens
local optionPressed = false
local optionOtherKey = false
local optionHoldActive = false
local pendingReleaseTimer = nil
local function centerMouseOn(scr)
  if not scr then return end
  if dragging then
    local win = window.focusedWindow()
    if win then win:moveToScreen(scr) end
  end
  local f = scr:frame()
  setMousePosition({ x = f.x + f.w / 2, y = f.y + f.h / 2 })
end
optionFlagsWatcher = eventtap.new({ eventtap.event.types.flagsChanged }, function(e)
  local f = e:getFlags()
  if f.alt and not optionHoldActive then
    optionHoldActive = true
    optionOtherKey = false
    if pendingReleaseTimer then
      pendingReleaseTimer:stop()
      pendingReleaseTimer = nil
    end
  elseif not f.alt and optionHoldActive then
    optionHoldActive = false
    if not optionOtherKey then
      pendingReleaseTimer = timer.doAfter(0.05, function()
        pendingReleaseTimer = nil
        if not optionHoldActive then
          local currentScr = mouse.getCurrentScreen()
          local allScr = hs.screen.allScreens()
          table.sort(allScr, function(a,b) return a:frame().x < b:frame().x end)
          local currentIndex = 1
          for i, s in ipairs(allScr) do
            if s:id() == currentScr:id() then currentIndex = i; break end
          end
          local nextIndex = (currentIndex % #allScr) + 1
          centerMouseOn(allScr[nextIndex])
        end
      end)
    else
      -- Cancel any pending timer if optionOtherKey was set
      if pendingReleaseTimer then
        pendingReleaseTimer:stop()
        pendingReleaseTimer = nil
      end
    end
  end
end)
optionFlagsWatcher:start()
optionKeyWatcher = eventtap.new({ eventtap.event.types.keyDown }, function(e)
  if optionHoldActive or pendingReleaseTimer then
    local f = e:getFlags()
    if f.alt and not (f.cmd or f.ctrl or f.shift) then
      local kc = e:getKeyCode()
      if kc == hs.keycodes.map.d then
        optionOtherKey = true
        eventtap.scrollWheel({0, -400}, {}, "pixel")
        return true
      elseif kc == hs.keycodes.map.u then
        optionOtherKey = true
        eventtap.scrollWheel({0, 400}, {}, "pixel")
        return true
      end
    end
    optionOtherKey = true
    if pendingReleaseTimer then
      pendingReleaseTimer:stop()
      pendingReleaseTimer = nil
    end
  end
  return false
end)
optionKeyWatcher:start()
-- Control-tap: click bottom-right of VSCode's screen (Copilot area), or bottom-middle if VSCode not found
-- Only works in normal mode (unlike Option-tap which works globally)
local ctrlPressed, ctrlOtherKey = false, false
local modalActive = false

-- Track modal state
local originalEntered = modal.entered
modal.entered = function(self)
  modalActive = true
  originalEntered(self)
end

local originalExited = modal.exited
modal.exited = function(self)
  modalActive = false
  originalExited(self)
end

local function clickNextScreenBottomRight()
  local currentScr = mouse.getCurrentScreen()
  local targetScr = nil
  local isVSCodeActive = false
 
  -- Try to find VSCode and check if it's actually visible/active
  local vscodeApp = app.find("Visual Studio Code") or app.find("Code")
  if vscodeApp then
    local vscodeWindow = vscodeApp:mainWindow()
    if vscodeWindow and not vscodeWindow:isMinimized() and vscodeWindow:isVisible() then
      targetScr = vscodeWindow:screen()
      isVSCodeActive = true
    end
  end
 
  -- If no active VSCode found, use next screen
  if not targetScr then
    local allScr = hs.screen.allScreens()
    if #allScr > 1 then
      table.sort(allScr, function(a,b) return a:frame().x < b:frame().x end)
      local currentIndex = 1
      for i, s in ipairs(allScr) do
        if s:id() == currentScr:id() then currentIndex = i; break end
      end
      local nextIndex = (currentIndex % #allScr) + 1
      targetScr = allScr[nextIndex]
    else
      targetScr = currentScr
    end
  end
 
  if dragging then
    local win = window.focusedWindow()
    if win then win:moveToScreen(targetScr) end
  end
 
  local f = targetScr:frame()
  local pos
  if isVSCodeActive then
    -- VSCode active and visible: click bottom-right (Copilot chat area)
    pos = { x = f.x + f.w - 250, y = f.y + f.h - 100 }
  else
    -- VSCode not active/visible: click bottom-middle
    pos = { x = f.x + f.w / 2, y = f.y + f.h - 100 }
  end
 
  setMousePosition(pos)
  if not dragging then eventtap.leftClick(pos) end
end
ctrlFlagsWatcher = eventtap.new({ eventtap.event.types.flagsChanged }, function(e)
  -- Only work when modal is active (in normal mode)
  if not modalActive then return false end
  
  local f = e:getFlags()
  if f.ctrl and not ctrlPressed then
    ctrlPressed = true
    ctrlOtherKey = false
  elseif not f.ctrl and ctrlPressed then
    ctrlPressed = false
    if not ctrlOtherKey then 
      clickNextScreenBottomRight()
      modal:exit()  -- Exit nav mode after performing the action
    end
  end
end)
ctrlFlagsWatcher:start()
ctrlKeyWatcher = eventtap.new({ eventtap.event.types.keyDown }, function(e)
  if ctrlPressed then ctrlOtherKey = true end
  return false
end)
ctrlKeyWatcher:start()
-- End of configuration.
-- Credit: Artur Grochau – github.com/arturgrochau
