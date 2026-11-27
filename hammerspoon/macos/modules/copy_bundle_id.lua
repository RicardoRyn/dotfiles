-- 绑定 Cmd + / 来复制并显示当前 App 的 Bundle ID
local M = {}

M.hotkey = hs.hotkey.bind({ "alt" }, "/", function()
  local frontApp = hs.application.frontmostApplication()
  if frontApp then
    local bundleID = frontApp:bundleID()
    if bundleID then
      hs.pasteboard.setContents(bundleID)
      hs.alert.show("Copy: " .. bundleID)
    end
  end
end)

return M
