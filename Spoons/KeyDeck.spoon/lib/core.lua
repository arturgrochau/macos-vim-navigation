-- Core "machine": shared mutable state and the low-level mouse / scroll /
-- hold-to-repeat helpers used by the feature modules, parameterized by
-- cfg.tuning so they can be configured.
--
-- A single ctx table is created in init.lua and passed to every module, so
-- modules observe each other's state by reference.
local Core = {}

function Core.new(hs, modal, cfg)
  local mouse, eventtap, screen, timer = hs.mouse, hs.eventtap, hs.screen, hs.timer
  local t = cfg.tuning
  local naturalScroll = hs.mouse.scrollDirection().natural

  local ctx = {
    hs = hs, modal = modal, cfg = cfg,
    mouse = mouse, eventtap = eventtap, screen = screen,
    window = hs.window, app = hs.application, timer = timer,
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

  -- Move the pointer.
  function ctx.setMousePosition(pos)
    mouse.absolutePosition(pos)
  end

  -- Move the pointer by a fraction of the main screen.
  function ctx.moveMouseByFraction(xFrac, yFrac)
    local scr = screen.mainScreen():frame()
    local p = mouse.absolutePosition()
    ctx.setMousePosition({ x = p.x + scr.w * xFrac, y = p.y + scr.h * yFrac })
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

  -- Bind a scroll-wheel key with hold-to-repeat.
  function ctx.bindScrollKey(key, initialOffsets, repeatOffsets)
    modal:bind({}, key,
      function()
        eventtap.scrollWheel(ctx.norm(initialOffsets), {}, "pixel")
        ctx.holdTimers[key] = {}
        ctx.holdTimers[key].delayTimer = timer.doAfter(t.scrollInitialDelay, function()
          ctx.holdTimers[key].repeatTimer = timer.doEvery(t.scrollRepeatInterval, function()
            eventtap.scrollWheel(ctx.norm(repeatOffsets), {}, "pixel")
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

  -- Perform `count` mouse clicks at the current pointer position.
  function ctx.performClicks(count)
    local pos = mouse.absolutePosition()
    for i = 1, count do
      local down = eventtap.event.newMouseEvent(eventtap.event.types.leftMouseDown, pos)
      down:setProperty(eventtap.event.properties.mouseEventClickState, i)
      down:post()
      eventtap.event.newMouseEvent(eventtap.event.types.leftMouseUp, pos):post()
    end
  end

  return ctx
end

return Core
