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

  -- Centered help panel listing every binding. `sections` is a list of
  -- { title = string, items = { {keyLabel, description}, ... } }.
  function self.showHelp(sections)
    if self.help then self.help:delete() end
    local scr = mouse.getCurrentScreen():frame()
    local W, lineH, pad = 460, 22, 18
    local rows = 1 -- header
    for _, s in ipairs(sections) do rows = rows + 1 + #s.items end
    local H = pad * 2 + rows * lineH + 8
    self.help = canvas.new({
      x = scr.x + (scr.w - W) / 2, y = scr.y + (scr.h - H) / 2, w = W, h = H,
    })
    local elems = { {
      type = "rectangle", action = "fill",
      fillColor = { alpha = 0.93, red = 0.10, green = 0.10, blue = 0.12 },
      roundedRectRadii = { xRadius = 12, yRadius = 12 },
    } }
    local cy = pad
    local function text(str, x, w, size, color, font)
      table.insert(elems, {
        type = "text", text = str, textSize = size, textColor = color, textFont = font,
        frame = { x = x, y = cy, w = w, h = lineH },
      })
    end
    text("Navigation Mode — shortcuts  (press ? to close)", pad, W - pad * 2, 14, { white = 1 }, "Menlo-Bold")
    cy = cy + lineH + 6
    for _, s in ipairs(sections) do
      text(s.title, pad, W - pad * 2, 12, { red = 0.6, green = 0.8, blue = 1, alpha = 1 }, "Menlo-Bold")
      cy = cy + lineH
      for _, it in ipairs(s.items) do
        text(it[1], pad + 8, 132, 12, { white = 0.95 }, "Menlo")
        text(it[2], pad + 148, W - pad * 2 - 148, 12, { white = 0.6 }, "Menlo")
        cy = cy + lineH
      end
    end
    self.help:appendElements(elems)
    self.help:show()
  end

  function self.hideHelp()
    if self.help then self.help:delete(); self.help = nil end
  end

  return self
end

return Overlay
