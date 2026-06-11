-- Visual selection mode: v / Shift+v to enter (drag-select or triple-click
-- block), y to yank (Cmd+C), p / Shift+p to paste (Cmd+V). Selection is extended
-- by the movement/scroll keys in nav.lua via the shared ctx.dragging state.
local M = {}

function M.setup(ctx)
  local modal, eventtap, mouse, timer = ctx.modal, ctx.eventtap, ctx.mouse, ctx.timer
  local overlay = ctx.overlay

  -- Toggle plain visual mode (start/finish a drag selection).
  modal:bind({}, "v", function()
    local pos = mouse.absolutePosition()
    if ctx.mode == "visual" then
      ctx.endDragAndClick(pos)
      ctx.dragging = false
      ctx.mode = "normal"
      overlay.hideVisual()
    else
      ctx.dragging = true
      eventtap.event.newMouseEvent(eventtap.event.types.leftMouseDown, pos):post()
      ctx.mode = "visual"
      overlay.showVisual()
    end
  end)

  -- Shift+v: visual mode seeded with a triple-click block selection.
  modal:bind({ "shift" }, "v", function()
    local pos = mouse.absolutePosition()
    if ctx.mode == "visual" then
      ctx.endDragAndClick(pos)
      ctx.dragging = false
      ctx.mode = "normal"
      overlay.hideVisual()
    else
      ctx.performClicks(3, true)
      ctx.dragging = true
      ctx.mode = "visual"
      overlay.showVisual()
    end
  end)

  -- Yank: copy selection in visual mode, else a plain Cmd+C.
  modal:bind({}, "y", function()
    if ctx.mode == "visual" and ctx.dragging then
      ctx.endDragAndClick(mouse.absolutePosition(), "c")
      ctx.mode = "normal"
      overlay.hideVisual()
    else
      eventtap.keyStroke({ "cmd" }, "c")
    end
  end)

  -- Paste (and exit NAV MODE so the user can type immediately).
  local function paste()
    if ctx.mode == "visual" and ctx.dragging then
      ctx.endDragAndClick(mouse.absolutePosition(), "v")
      ctx.mode = "normal"
      overlay.hideVisual()
    else
      local pos = mouse.absolutePosition()
      eventtap.leftClick(pos)
      timer.doAfter(0.05, function()
        eventtap.keyStroke({ "cmd" }, "v")
        timer.doAfter(0.05, function() modal:exit() end)
      end)
    end
  end
  modal:bind({}, "p", paste)
  modal:bind({ "shift" }, "p", paste)
end

return M
