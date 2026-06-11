-- NAV MODE: the modal core. Owns the modal lifecycle (enter/exit + overlays),
-- vim-style pointer movement (hjkl), scrolling (d/u/w/b, arrows, ctrl/shift
-- variants), clicks (i/a), window focus cycling, and gg/G scroll-to-edge.
--
-- The hjkl/scroll keys are intentionally fixed vim conventions; what the user
-- rebinds via config is the set of keys that ENTER/EXIT the mode (features.nav).
local M = {}

function M.setup(ctx)
  local hs, modal, eventtap, mouse, screen, window, timer =
    ctx.hs, ctx.modal, ctx.eventtap, ctx.mouse, ctx.screen, ctx.window, ctx.timer
  local overlay = ctx.overlay
  local t = ctx.cfg.tuning
  local scrollStep = t.scrollStep
  local scrollLargeStep = scrollStep

  -- Modal lifecycle + overlays. The exit hook finalizes a pending visual selection.
  function modal:entered()
    ctx.navActive = true
    overlay.createNormal()
  end
  function modal:exited()
    ctx.navActive = false
    overlay.hideNormal()
    overlay.hideHelp()
    ctx.helpVisible = false
    if ctx.mode == "visual" then
      local pos = mouse.absolutePosition()
      if ctx.dragging then
        eventtap.event.newMouseEvent(eventtap.event.types.leftMouseUp, pos):post()
        ctx.dragging = false
      end
      timer.doAfter(0.05, function() eventtap.leftClick(pos) end)
      ctx.mode = "normal"
      overlay.hideVisual()
    end
  end

  -- Directional pointer movement: hjkl (1/8 screen) and HJKL (1/2 screen).
  local directions = {
    { mod = {},          key = "h", frac = 1/8, dx = -1, dy = 0 },
    { mod = {},          key = "l", frac = 1/8, dx = 1,  dy = 0 },
    { mod = {},          key = "j", frac = 1/8, dx = 0,  dy = 1 },
    { mod = {},          key = "k", frac = 1/8, dx = 0,  dy = -1 },
    { mod = { "shift" }, key = "h", frac = 1/2, dx = -1, dy = 0 },
    { mod = { "shift" }, key = "l", frac = 1/2, dx = 1,  dy = 0 },
    { mod = { "shift" }, key = "j", frac = 1/2, dx = 0,  dy = 1 },
    { mod = { "shift" }, key = "k", frac = 1/2, dx = 0,  dy = -1 },
  }
  for _, dir in ipairs(directions) do
    local xFrac, yFrac = dir.dx * dir.frac, dir.dy * dir.frac
    ctx.bindHoldWithDelay(dir.mod, dir.key, function() ctx.moveMouseByFraction(xFrac, yFrac) end,
      t.directionInitialDelay, t.directionRepeatInterval)
  end

  -- Scroll keys (d/u vertical, w/b horizontal) with drag-aware behavior.
  local dragFrac = t.dragMoveFrac
  local dragLargeFrac = dragFrac * 5
  ctx.bindScrollKey("d", { 0, -scrollLargeStep }, { 0, -scrollStep },
    function() ctx.moveMouseByFraction(0, dragLargeFrac) end,
    function() ctx.moveMouseByFraction(0, dragFrac) end)
  ctx.bindScrollKey("u", { 0, scrollLargeStep }, { 0, scrollStep },
    function() ctx.moveMouseByFraction(0, -dragLargeFrac) end,
    function() ctx.moveMouseByFraction(0, -dragFrac) end)
  ctx.bindScrollKey("w", { -scrollLargeStep, 0 }, { -scrollStep, 0 },
    function() ctx.moveMouseByFraction(ctx.mode == "visual" and dragLargeFrac or -dragLargeFrac, 0) end,
    function() ctx.moveMouseByFraction(ctx.mode == "visual" and dragFrac or -dragFrac, 0) end)
  ctx.bindScrollKey("b", { scrollLargeStep, 0 }, { scrollStep, 0 },
    function() ctx.moveMouseByFraction(ctx.mode == "visual" and -dragLargeFrac or dragLargeFrac, 0) end,
    function() ctx.moveMouseByFraction(ctx.mode == "visual" and -dragFrac or dragFrac, 0) end)

  -- Arrow keys: up/down scroll (like u/d), left/right move pointer (like h/l).
  ctx.bindScrollKey("down", { 0, -scrollLargeStep }, { 0, -scrollStep },
    function() ctx.moveMouseByFraction(0, dragLargeFrac) end,
    function() ctx.moveMouseByFraction(0, dragFrac) end)
  ctx.bindScrollKey("up", { 0, scrollLargeStep }, { 0, scrollStep },
    function() ctx.moveMouseByFraction(0, -dragLargeFrac) end,
    function() ctx.moveMouseByFraction(0, -dragFrac) end)
  for _, dir in ipairs({ { key = "left", dx = -1 }, { key = "right", dx = 1 } }) do
    local xFrac = dir.dx * (1/8)
    ctx.bindHoldWithDelay({}, dir.key, function() ctx.moveMouseByFraction(xFrac, 0) end,
      t.directionInitialDelay, t.directionRepeatInterval)
  end

  -- Large (shift) and medium (ctrl) scroll variants.
  local largeScrollStep = scrollStep * 8
  for _, sc in ipairs({
    { mod = { "shift" }, key = "u", delta = { 0, largeScrollStep } },
    { mod = { "shift" }, key = "d", delta = { 0, -largeScrollStep } },
    { mod = { "shift" }, key = "w", delta = { -largeScrollStep, 0 } },
    { mod = { "shift" }, key = "b", delta = { largeScrollStep, 0 } },
  }) do
    ctx.bindHoldWithDelay(sc.mod, sc.key, function()
      eventtap.scrollWheel(ctx.norm(sc.delta), {}, "pixel")
    end, t.scrollInitialDelay, t.scrollRepeatInterval)
  end
  local mediumScrollStep = scrollStep * 3
  for _, sc in ipairs({
    { mod = { "ctrl" }, key = "u", delta = { 0, mediumScrollStep } },
    { mod = { "ctrl" }, key = "d", delta = { 0, -mediumScrollStep } },
  }) do
    ctx.bindHoldWithDelay(sc.mod, sc.key, function()
      eventtap.scrollWheel(ctx.norm(sc.delta), {}, "pixel")
    end, t.scrollInitialDelay, t.scrollRepeatInterval)
  end

  -- Clicks: triple-click line select (i), right-click (a).
  modal:bind({}, "i", function() ctx.performClicks(3, false) end)
  modal:bind({}, "a", function() eventtap.rightClick(mouse.absolutePosition()) end)

  -- Window focus cycling and center-mouse.
  local function focusAppOffset(offset)
    local wins = window.visibleWindows()
    local cur = window.focusedWindow()
    if not cur then return end
    for idx, w in ipairs(wins) do
      if w:id() == cur:id() then
        local nextWin = wins[(idx + offset - 1) % #wins + 1]
        if nextWin then nextWin:focus() end
        return
      end
    end
  end
  modal:bind({ "shift" }, "a", function() focusAppOffset(1) end)
  modal:bind({ "shift" }, "i", function() focusAppOffset(-1) end)
  modal:bind({ "shift" }, "m", function()
    local f = screen.mainScreen():frame()
    ctx.setMousePosition({ x = f.x + f.w / 2, y = f.y + f.h / 2 })
  end)

  -- Vim-style scroll-to-edge: gg (top), G (bottom).
  local gPending, gTimer = false, nil
  local gDoubleDelay = 0.3
  local function scrollToTop() eventtap.event.newScrollEvent(ctx.norm({ 0, 1000000 }), {}, "pixel"):post() end
  local function scrollToBottom() eventtap.event.newScrollEvent(ctx.norm({ 0, -1000000 }), {}, "pixel"):post() end
  modal:bind({}, "g", function()
    if gPending then
      if gTimer then gTimer:stop(); gTimer = nil end
      gPending = false
      scrollToTop()
    else
      gPending = true
      gTimer = timer.doAfter(gDoubleDelay, function() gPending = false; gTimer = nil end)
    end
  end)
  modal:bind({ "shift" }, "g", function()
    gPending = false
    if gTimer then gTimer:stop(); gTimer = nil end
    scrollToBottom()
  end)
  ctx.gResetTap = eventtap.new({ eventtap.event.types.keyDown }, function(e)
    if gPending then
      local chars = e:getCharacters() or ""
      if chars:lower() ~= "g" then
        gPending = false
        if gTimer then gTimer:stop(); gTimer = nil end
      end
    end
    return false
  end)
  ctx.gResetTap:start()

  -- Toggle NAV MODE. Exposed on ctx so the Spoon's bindHotkeys() can map it.
  local function toggle()
    if ctx.navActive then modal:exit() else modal:enter() end
  end
  ctx.toggleNav = toggle

  -- A config key is bindable only if it's a non-empty string ("" means unbound).
  local function bindable(k) return type(k) == "string" and #k > 0 end

  -- Modifier name → its keycodes (left/right) and the flag it sets.
  local MODIFIERS = {
    alt       = { codes = { 58, 61 }, flag = "alt" },
    leftAlt   = { codes = { 58 },     flag = "alt" },
    rightAlt  = { codes = { 61 },     flag = "alt" },
    cmd       = { codes = { 54, 55 }, flag = "cmd" },
    leftCmd   = { codes = { 55 },     flag = "cmd" },
    rightCmd  = { codes = { 54 },     flag = "cmd" },
    ctrl      = { codes = { 59, 62 }, flag = "ctrl" },
    leftCtrl  = { codes = { 59 },     flag = "ctrl" },
    rightCtrl = { codes = { 62 },     flag = "ctrl" },
    shift     = { codes = { 56, 60 }, flag = "shift" },
  }
  local function hasCode(codes, kc)
    for _, c in ipairs(codes) do if c == kc then return true end end
    return false
  end
  local function otherFlagSet(f, flag)
    for _, k in ipairs({ "cmd", "alt", "ctrl", "shift" }) do
      if k ~= flag and f[k] then return true end
    end
    return false
  end

  -- Watch a modifier for a CLEAN tap (pressed alone, no other key) and call
  -- handlers.onPress / handlers.onRelease accordingly. This is the "activate on
  -- release without stealing combos" behavior.
  local function watchModifierTap(modName, handlers)
    local m = MODIFIERS[modName] or MODIFIERS.rightAlt
    local held, otherKey = false, false
    ctx.navActivatorFlags = eventtap.new({ eventtap.event.types.flagsChanged }, function(e)
      local f, kc = e:getFlags(), e:getKeyCode()
      if hasCode(m.codes, kc) and f[m.flag] then
        held = not otherFlagSet(f, m.flag)
        otherKey = false
        if held and handlers.onPress then handlers.onPress() end
      elseif hasCode(m.codes, kc) and not f[m.flag] then
        if held and not otherKey and handlers.onRelease then handlers.onRelease() end
        held = false
      elseif held then
        otherKey = true
      end
      return false
    end)
    ctx.navActivatorFlags:start()
    ctx.navActivatorKeys = eventtap.new({ eventtap.event.types.keyDown }, function()
      if held then otherKey = true end
      return false
    end)
    ctx.navActivatorKeys:start()
  end

  -- Activation dispatch.
  local nav = ctx.cfg.features.nav
  local act = nav.activator
  if act and act.kind == "tapModifier" then
    if act.onRelease == false then
      watchModifierTap(act.modifier or "rightAlt", { onPress = toggle })
    else
      watchModifierTap(act.modifier or "rightAlt", { onRelease = toggle })
    end
  elseif act and act.kind == "doubleTapModifier" then
    local last = 0
    watchModifierTap(act.modifier or "rightAlt", { onRelease = function()
      local now = timer.secondsSinceEpoch()
      if (now - last) < 0.35 then last = 0; toggle() else last = now end
    end })
  elseif act and (act.kind == "hotkey" or act.kind == "hyper") then
    local hk = act.hotkey or {}
    if bindable(hk.key) then ctx.bindGlobal(hk.mods or {}, hk.key, toggle) end
  elseif act and act.kind == "capsLock" then
    ctx.bindGlobal({}, "f18", toggle) -- the GUI remaps Caps Lock → F18
  else
    for _, b in ipairs(nav.enterKeys or {}) do
      if bindable(b.key) then ctx.bindGlobal(b.mods or {}, b.key, function() modal:enter() end) end
    end
  end

  -- Exit keys (e.g. escape) always apply.
  for _, b in ipairs(nav.exitKeys or {}) do
    if bindable(b.key) then modal:bind(b.mods or {}, b.key, function() modal:exit() end) end
  end

  -- In-mode help overlay: '?' (shift+/) lists every binding, built from config.
  local function buildHelp()
    local sections = {
      { title = "Navigation", items = {
        { "h j k l", "Move pointer" }, { "d / u", "Scroll down / up" },
        { "gg / G", "Top / bottom" }, { "v", "Select" }, { "y / p", "Copy / paste" },
        { "Esc", "Leave Navigation Mode" },
      } },
    }
    local launchers = {}
    for _, a in ipairs(ctx.cfg.apps or {}) do
      local label = (a.mods and #a.mods > 0 and "⇧" or "") .. (a.key or ""):upper()
      table.insert(launchers, { label, (a.names and a.names[1]) or a.bundleID or "App" })
    end
    if #launchers > 0 then table.insert(sections, { title = "App Launchers", items = launchers }) end
    local mon = ctx.cfg.features.monitors
    if mon and mon.enabled then
      local disp = {}
      if mon.nextDisplay and mon.nextDisplay.key then table.insert(disp, { "Next", "Next display" }) end
      if mon.prevDisplay and mon.prevDisplay.key then table.insert(disp, { "Prev", "Previous display" }) end
      if mon.jumpKeys and #mon.jumpKeys > 0 then table.insert(disp, { "⌥1 ⌥2 ⌥3", "Jump to display" }) end
      if #disp > 0 then table.insert(sections, { title = "Displays", items = disp }) end
    end
    return sections
  end
  modal:bind({ "shift" }, "/", function()
    if ctx.helpVisible then
      overlay.hideHelp(); ctx.helpVisible = false
    else
      overlay.showHelp(buildHelp()); ctx.helpVisible = true
    end
  end)
end

return M
