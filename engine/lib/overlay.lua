-- On-screen mode overlays: "-- NORMAL --" while NAV MODE is active and
-- "-- VISUAL MODE --" while a selection is in progress. Faithful extraction of
-- the original createOverlay / showVisualIndicator / hideVisualIndicator helpers.
local Overlay = {}

function Overlay.new(ctx)
  local canvas, mouse = ctx.hs.canvas, ctx.mouse
  local self = { normal = nil, visual = nil }

  function self.createNormal()
    if self.normal then self.normal:delete() end
    local scr = mouse.getCurrentScreen():frame()
    self.normal = canvas.new({
      x = scr.x + scr.w - 210, y = scr.y + scr.h - 130, h = 30, w = 200,
    }):appendElements({
      type = "rectangle", action = "fill",
      fillColor = { alpha = 0.4, red = 0, green = 0, blue = 0 },
      roundedRectRadii = { xRadius = 8, yRadius = 8 },
    }, {
      id = "modeText", type = "text", text = "-- NORMAL --",
      textSize = 14, textColor = { white = 1 },
      frame = { x = 0, y = 5, h = 30, w = 200 }, textAlignment = "center",
    })
    self.normal:show()
  end

  function self.hideNormal()
    if self.normal then self.normal:hide() end
  end

  function self.showVisual()
    if self.visual then return end
    local scr = mouse.getCurrentScreen():frame()
    self.visual = canvas.new({
      x = scr.x + scr.w - 210, y = scr.y + scr.h - 90, w = 200, h = 30,
    }):appendElements({
      type = "rectangle", action = "fill",
      fillColor = { red = 0.2, green = 0.2, blue = 1, alpha = 0.5 },
      roundedRectRadii = { xRadius = 8, yRadius = 8 },
    }, {
      type = "text", text = "-- VISUAL MODE --",
      textSize = 14, textColor = { white = 1 },
      frame = { x = 0, y = 5, h = 30, w = 200 }, textAlignment = "center",
    })
    self.visual:show()
  end

  function self.hideVisual()
    if self.visual then
      self.visual:delete()
      self.visual = nil
    end
  end

  return self
end

return Overlay
