--------------------------------------------------------------------------------
-- 启用 Hammerspoon 的命令行接口 (IPC)
--------------------------------------------------------------------------------
require("hs.ipc")

--------------------------------------------------------------------------------
-- 自定义模块
--------------------------------------------------------------------------------
require("modules.copy_bundle_id")
require("modules.zen_tabs")
require("modules.glass_launcher")

--------------------------------------------------------------------------------
-- 重载通知
--------------------------------------------------------------------------------
local key = "ReloadWatcher"
local pid = hs.application.get(hs.processInfo.bundleID):pid()
if hs.settings.get(key) == pid then
    hs.notify.new({ title = "Hammerspoon", informativeText = "Configuration reloaded" }):send()
end
hs.settings.set(key, pid)
