-- Core "machine": shared mutable state and the low-level mouse / scroll / drag /
-- hold-to-repeat helpers used by the feature modules. This is a faithful extraction
-- of the helpers that used to live as top-level locals in the original init.lua,
-- parameterized by cfg.tuning so they can be configured.
--
-- A single ctx table is created in init.lua and passed to every module. Shared
-- state (ctx.mode, ctx.dragging) lives on this table so modules observe each
-- other's changes by reference.
local Core = {}

function Core.new(hs, modal, cfg)
  local mouse, eventtap, screen, timer = hs.mouse, hs.eventtap, hs.screen, hs.timer
  local t = cfg.tuning
  local naturalScroll = hs.mouse.scrollDirection().natural

  local ctx = {
    hs = hs, modal = modal, cfg = cfg,
    mouse = mouse, eventtap = eventtap, screen = screen,
    window = hs.window, app = hs.application, timer = timer,
    -- shared mutable state
    mode = "normal",     -- "normal" | "visual"
    dragging = false,
    -- timer bookkeeping for hold-to-repeat
    held = {},
    holdTimers = {},
    -- every global hotkey is registered here so the Spoon's stop() can delete it
    hotkeys = {},
  }

  -- Bind a global hotkey and track it for teardown. Modules use this instead
  -- of hs.hotkey.bind directly.
  function ctx.bindGlobal(mods, key, pressed, released)
    local hk = hs.hotkey.bind(mods, key, pressed, released)
    if hk then table.insert(ctx.hotkeys, hk) end
    return hk
  end

  -- Invert scroll deltas when natural scrolling is on, matching system behavior.
  function ctx.norm(delta)
    if not naturalScroll then return delta end
    return { delta[1] * -1, delta[2] * -1 }
  end

  -- Move the pointer; in visual mode this drags the active selection.
  function ctx.setMousePosition(pos)
    if ctx.dragging then
      eventtap.event.newMouseEvent(eventtap.event.types.leftMouseDragged, pos):post()
    end
    mouse.absolutePosition(pos)
  end

  -- Move the pointer by a fraction of the main screen, starting a drag if we are
  -- in visual mode and not already dragging.
  function ctx.moveMouseByFraction(xFrac, yFrac)
    local scr = screen.mainScreen():frame()
    local p = mouse.absolutePosition()
    if ctx.mode == "visual" and not ctx.dragging then
      ctx.dragging = true
      eventtap.event.newMouseEvent(eventtap.event.types.leftMouseDown, p):post()
    end
    ctx.setMousePosition({ x = p.x + scr.w * xFrac, y = p.y + scr.h * yFrac })
  end

  -- Bind a modal key that fires fn on press and repeats it at a fixed interval
  -- while held.
  function ctx.bindHeld(mod, key, fn)
    modal:bind(mod, key,
      function()
        fn()
        ctx.held[key] = timer.doEvery(t.scrollRepeatInterval, fn)
      end,
      function()
        if ctx.held[key] then ctx.held[key]:stop(); ctx.held[key] = nil end
      end)
  end

  -- Bind a modal key that fires fn on press, waits `delay`, then repeats every
  -- `interval` while held.
  function ctx.bindHoldWithDelay(mod, key, fn, delay, interval)
    modal:bind(mod, key,
      function()
        fn()
        ctx.holdTimers[key] = {}
        ctx.holdTimers[key].delayTimer = timer.doAfter(delay, function()
          ctx.holdTimers[key].repeatTimer = timer.doEvery(interval, fn)
        end)
      end,
      function()
        local h = ctx.holdTimers[key]
        if h then
          if h.delayTimer then h.delayTimer:stop() end
          if h.repeatTimer then h.repeatTimer:stop() end
          ctx.holdTimers[key] = nil
        end
      end)
  end

  -- Bind a scroll key with separate non-drag (scroll wheel) and drag (selection
  -- extend) behaviors, plus hold-to-repeat.
  function ctx.bindScrollKey(key, initialOffsets, repeatOffsets, initialDragFn, repeatDragFn)
    modal:bind({}, key,
      function()
        if ctx.dragging then initialDragFn()
        else eventtap.scrollWheel(ctx.norm(initialOffsets), {}, "pixel") end
        ctx.holdTimers[key] = {}
        ctx.holdTimers[key].delayTimer = timer.doAfter(t.scrollInitialDelay, function()
          ctx.holdTimers[key].repeatTimer = timer.doEvery(t.scrollRepeatInterval, function()
            if ctx.dragging then repeatDragFn()
            else eventtap.scrollWheel(ctx.norm(repeatOffsets), {}, "pixel") end
          end)
        end)
      end,
      function()
        local h = ctx.holdTimers[key]
        if h then
          if h.delayTimer then h.delayTimer:stop() end
          if h.repeatTimer then h.repeatTimer:stop() end
          ctx.holdTimers[key] = nil
        end
      end)
  end

  -- Perform `count` mouse clicks at the current pointer, optionally leaving the
  -- final button held down (used to start a triple-click selection drag).
  function ctx.performClicks(count, keepLastDown)
    local pos = mouse.absolutePosition()
    for i = 1, count do
      local down = eventtap.event.newMouseEvent(eventtap.event.types.leftMouseDown, pos)
      down:setProperty(eventtap.event.properties.mouseEventClickState, i)
      down:post()
      if i < count or not keepLastDown then
        eventtap.event.newMouseEvent(eventtap.event.types.leftMouseUp, pos):post()
      end
    end
  end

  -- Release any active drag and optionally run a Cmd+<action> (e.g. copy/paste)
  -- followed by a click to settle the selection.
  function ctx.endDragAndClick(pos, action)
    if ctx.dragging then
      eventtap.event.newMouseEvent(eventtap.event.types.leftMouseUp, pos):post()
      ctx.dragging = false
    end
    if action then
      timer.doAfter(0.05, function()
        eventtap.keyStroke({ "cmd" }, action)
        timer.doAfter(0.05, function() eventtap.leftClick(pos) end)
      end)
    else
      timer.doAfter(0.05, function() eventtap.leftClick(pos) end)
    end
  end

  return ctx
end

return Core
