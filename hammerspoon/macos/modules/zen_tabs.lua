-- 在 Zen 浏览器中使用 Cmd + J/K 快捷键切换标签页
local M = {}

local zenBundleID = "app.zen-browser.zen"

M.tap = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
  local frontApp = hs.application.frontmostApplication()

  if frontApp and frontApp:bundleID() == zenBundleID then
    local keyCode = event:getKeyCode()
    local flags = event:getFlags()

    -- 确保只按下了 Cmd 键（没有按其他修饰键）
    if flags.cmd and not flags.alt and not flags.ctrl and not flags.shift then
      local keyJ = hs.keycodes.map["J"]
      local keyK = hs.keycodes.map["K"]

      if keyCode == keyJ then
        hs.eventtap.keyStroke({ "alt", "cmd" }, "down")
        return true -- 拦截
      elseif keyCode == keyK then
        hs.eventtap.keyStroke({ "alt", "cmd" }, "up")
        return true -- 拦截
      end
    end
  end
  -- 如果不是 Zen，或者按的不是 J/K，返回 false 放行给系统
  return false
end)

M.tap:start()

return M
