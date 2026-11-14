-- 启用 Hammerspoon 的命令行接口 (IPC)
require("hs.ipc")

--------------------------------------------------------------------------------
-- 在 Zen 浏览器中使用 Cmd + J/K 快捷键切换标签页
--------------------------------------------------------------------------------
local zenBundleID = "app.zen-browser.zen"
-- 创建一个按键监听器
zenTabSwitcher = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
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
-- 启动监听器
zenTabSwitcher:start()

--------------------------------------------------------------------------------
-- 绑定 Cmd + / 来显示当前 App 的 Bundle ID
--------------------------------------------------------------------------------
hs.hotkey.bind({ "cmd" }, "/", function()
  local frontApp = hs.application.frontmostApplication()
  if frontApp then
    local bundleID = frontApp:bundleID()
    if bundleID then
      hs.pasteboard.setContents(bundleID)
      hs.alert.show("Copy: " .. bundleID)
    end
  end
end)

--------------------------------------------------------------------------------
-- 启动器
--------------------------------------------------------------------------------
hs.loadSpoon("Seal")
spoon.Seal:loadPlugins({ "apps", "pasteboard", "calc" })
local pb = spoon.Seal.plugins.pasteboard
pb.historySize = 100
pb.saveHistory = true
spoon.Seal:bindHotkeys({
  show = { { "ctrl" }, "space" },
})
spoon.Seal:start()

--------------------------------------------------------------------------------
-- Caffeine
--------------------------------------------------------------------------------
hs.loadSpoon("Caffeine")
spoon.Caffeine:bindHotkeys({
  toggle = { { "ctrl", "alt" }, "c" },
})
spoon.Caffeine:start()
