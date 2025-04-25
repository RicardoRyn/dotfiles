local wezterm = require("wezterm")
local mux = wezterm.mux

-- -- 真全屏
-- local function real_fullscreen(window)
--     local tab, pane, window = mux.spawn_window(cmd or {})
--     local gui_window = window:gui_window()
--     gui_window:perform_action(wezterm.action.ToggleFullScreen, pane)
-- end

local function false_fullscreen(window)
  local tab, pane, window = mux.spawn_window(cmd or {})
  local gui_window = window:gui_window()
  gui_window:maximize()
end

return {
  -- 注册到 WezTerm 的 `gui-startup` 事件（关键步骤！）
  -- wezterm.on('gui-startup', real_fullscreen),
  wezterm.on("gui-startup", false_fullscreen),
}
