-- Global cursor movement outside NAV MODE (default ⌥⌘⇧ + hjkl), with a click key.
-- A single tap moves a large step; holding repeats a smaller step quickly. Ported
-- from the custom branch and made data-driven via features.cursor.
local M = {}

function M.setup(ctx)
  local hs, mouse, eventtap, timer = ctx.hs, ctx.mouse, ctx.eventtap, ctx.timer
  local t = ctx.cfg.tuning
  local feat = ctx.cfg.features.cursor
  local mods = feat.mods or { "alt", "cmd", "shift" }
  local keys = feat.keys or {}

  ctx.cursorTimers = {}

  local function moveBy(dx, dy)
    local p = mouse.absolutePosition()
    mouse.absolutePosition({ x = p.x + dx, y = p.y + dy })
  end

  local function bindCursor(key, dx, dy)
    if type(key) ~= "string" or #key == 0 then return end
    local tapDx = dx > 0 and t.globalCursorStep or (dx < 0 and -t.globalCursorStep or 0)
    local tapDy = dy > 0 and t.globalCursorStep or (dy < 0 and -t.globalCursorStep or 0)
    local holdDx = dx > 0 and t.globalCursorHoldStep or (dx < 0 and -t.globalCursorHoldStep or 0)
    local holdDy = dy > 0 and t.globalCursorHoldStep or (dy < 0 and -t.globalCursorHoldStep or 0)
    hs.hotkey.bind(mods, key,
      function()
        moveBy(tapDx, tapDy)
        ctx.cursorTimers[key] = {}
        ctx.cursorTimers[key].delayTimer = timer.doAfter(t.globalCursorRepeatDelay, function()
          ctx.cursorTimers[key].repeatTimer = timer.doEvery(t.globalCursorRepeatInterval, function()
            moveBy(holdDx, holdDy)
          end)
        end)
      end,
      function()
        local h = ctx.cursorTimers[key]
        if h then
          if h.delayTimer then h.delayTimer:stop() end
          if h.repeatTimer then h.repeatTimer:stop() end
          ctx.cursorTimers[key] = nil
        end
      end)
  end

  bindCursor(keys.left, -1, 0)
  bindCursor(keys.right, 1, 0)
  bindCursor(keys.up, 0, -1)
  bindCursor(keys.down, 0, 1)

  if type(keys.click) == "string" and #keys.click > 0 then
    hs.hotkey.bind(mods, keys.click, function()
      eventtap.leftClick(mouse.absolutePosition())
    end)
  end
end

return M
