-- Window management: hide the frontmost app, and restore (unhide + unminimize)
-- every application's windows. Bindings come from features.windows.
local M = {}

function M.setup(ctx)
  local hs = ctx.hs
  local feat = ctx.cfg.features.windows

  if feat.hide and type(feat.hide.key) == "string" and #feat.hide.key > 0 then
    hs.hotkey.bind(feat.hide.mods or {}, feat.hide.key, function()
      local a = hs.application.frontmostApplication()
      if a then a:hide() end
    end)
  end

  if feat.restore and type(feat.restore.key) == "string" and #feat.restore.key > 0 then
    hs.hotkey.bind(feat.restore.mods or {}, feat.restore.key, function()
      for _, a in ipairs(hs.application.runningApplications()) do
        if a:isHidden() then a:unhide() end
        for _, win in ipairs(a:allWindows()) do
          if win:isMinimized() then win:unminimize() end
        end
      end
    end)
  end
end

return M
