--------------------------------------------------------------------------------
-- 启用 Hammerspoon 的命令行接口 (IPC)
--------------------------------------------------------------------------------
require("hs.ipc")

--------------------------------------------------------------------------------
-- 液态玻璃启动器
--------------------------------------------------------------------------------
local launcher = require("search-launcher")
launcher.prewarm()
require("app-launchers")
require("launcher-file-conversions")
require("launcher-custom-actions")

--------------------------------------------------------------------------------
-- 自定义模块
--------------------------------------------------------------------------------
require("modules.copy_bundle_id")
require("modules.zen_tabs")

--------------------------------------------------------------------------------
-- 重载配置文件时的通知
--------------------------------------------------------------------------------
local key = "ReloadWatcher"
local pid = hs.application.get(hs.processInfo.bundleID):pid()
if hs.settings.get(key) == pid then
    hs.notify.new({ title = "Hammerspoon", informativeText = "Configuration reloaded" }):send()
end
hs.settings.set(key, pid)
