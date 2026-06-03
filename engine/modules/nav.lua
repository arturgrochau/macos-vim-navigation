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

  -- Toggle NAV MODE.
  local function toggle()
    if ctx.navActive then modal:exit() else modal:enter() end
  end

  -- Activation. `activator` is the primary path; fall back to legacy enterKeys.
  local nav = ctx.cfg.features.nav
  local activator = nav.activator
  if activator and activator.kind == "hotkey" then
    local hk = activator.hotkey or {}
    hs.hotkey.bind(hk.mods or {}, hk.key or "f12", toggle)
  elseif activator and (activator.kind == "rightCmd" or activator.kind == "rightAlt") then
    -- Tap a right-hand modifier to toggle. Guarded like the option-tap so it never
    -- fires when the modifier is part of a real combo (e.g. Right ⌘ + C).
    local targetKeyCode = activator.kind == "rightCmd" and 54 or 61  -- rightcmd / rightalt
    local flagField = activator.kind == "rightCmd" and "cmd" or "alt"
    local held, otherKey = false, false
    ctx.navActivatorFlags = eventtap.new({ eventtap.event.types.flagsChanged }, function(e)
      local f = e:getFlags()
      local kc = e:getKeyCode()
      if kc == targetKeyCode and f[flagField] then
        -- Press of the target modifier. Only a candidate if it's the ONLY modifier down.
        local lone = f[flagField] and not (f.cmd and f.alt) and not f.ctrl and not f.shift
          and not (flagField == "cmd" and f.alt) and not (flagField == "alt" and f.cmd)
        held = lone
        otherKey = false
      elseif kc == targetKeyCode and not f[flagField] then
        -- Release of the target modifier.
        if held and not otherKey then toggle() end
        held = false
      elseif held then
        -- Another modifier changed while holding → it's a combo, not a tap.
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
  else
    for _, b in ipairs(nav.enterKeys or {}) do
      hs.hotkey.bind(b.mods or {}, b.key, function() modal:enter() end)
    end
  end

  -- Exit keys (e.g. escape) always apply.
  for _, b in ipairs(nav.exitKeys or {}) do
    modal:bind(b.mods or {}, b.key, function() modal:exit() end)
  end
end

return M
