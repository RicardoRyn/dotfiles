local wezterm = require("wezterm")
local platform = require("utils.platform")
local act = wezterm.action

local mod = {}

if platform.is_mac then
  mod.SUPER = "SUPER"
  mod.SUPER_REV = "SUPER|CTRL"
elseif platform.is_win or platform.is_linux then
  mod.SUPER = "ALT" -- to not conflict with Windows key shortcuts
  mod.SUPER_REV = "ALT|CTRL"
end

-- 使用smart-splits.nvim
-- if you are *NOT* lazy-loading smart-splits.nvim (recommended)
local function is_vim(pane)
  -- this is set by the plugin, and unset on ExitPre in Neovim
  return pane:get_user_vars().IS_NVIM == "true"
end
local direction_keys = {
  h = "Left",
  j = "Down",
  k = "Up",
  l = "Right",
  LeftArrow = "Left",
  DownArrow = "Down",
  UpArrow = "Up",
  RightArrow = "Right",
}
local function split_nav(resize_or_move, key)
  return {
    key = key,
    mods = "CTRL",
    action = wezterm.action_callback(function(win, pane)
      if is_vim(pane) then
        -- 传递给nvim
        win:perform_action({
          SendKey = { key = key, mods = "CTRL" },
        }, pane)
      else
        if resize_or_move == "resize" then
          win:perform_action({ AdjustPaneSize = { direction_keys[key], 3 } }, pane)
        else
          win:perform_action({ ActivatePaneDirection = direction_keys[key] }, pane)
        end
      end
    end),
  }
end

-- stylua: ignore
local keys = {
  -- 通过smart-splits在panels之间移动
  split_nav('move', 'h'),
  split_nav('move', 'j'),
  split_nav('move', 'k'),
  split_nav('move', 'l'),
  split_nav("resize", "LeftArrow"),
  split_nav("resize", "DownArrow"),
  split_nav("resize", "UpArrow"),
  split_nav("resize", "RightArrow"),

  -- 显式绑定 <Ctrl-Enter> 并发送 escape 序列，使noevim能够捕获<C-CR>
  { key = "Enter", mods = "CTRL", action = wezterm.action.SendString("\x1b[13;5u") },

  -- misc/useful --
  { key = "c", mods = "LEADER", action = "ActivateCopyMode" },
  { key = "F2", mods = "NONE", action = act.ShowLauncher },
  -- { key = "F3", mods = "NONE", action = act.ActivateCommandPalette },
  -- { key = "F4", mods = "NONE", action = act.ShowLauncherArgs({ flags = "FUZZY|TABS" }) },
  -- { key = "F5", mods = "NONE", action = act.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES" }) },
  -- { key = "F11", mods = "NONE", action = act.ToggleFullScreen },
  -- { key = "F12", mods = "NONE", action = act.ShowDebugOverlay },
  { key = "f", mods = mod.SUPER_REV, action = act.Search({ CaseInSensitiveString = "" }) },
  -- {
  --   key = "u",
  --   mods = mod.SUPER_REV,
  --   action = wezterm.action.QuickSelectArgs({
  --     label = "open url",
  --     patterns = {
  --       "\\((https?://\\S+)\\)",
  --       "\\[(https?://\\S+)\\]",
  --       "\\{(https?://\\S+)\\}",
  --       "<(https?://\\S+)>",
  --       "\\bhttps?://\\S+[)/a-zA-Z0-9-]+",
  --     },
  --     action = wezterm.action_callback(function(window, pane)
  --       local url = window:get_selection_text_for_pane(pane)
  --       wezterm.log_info("opening: " .. url)
  --       wezterm.open_with(url)
  --     end),
  --   }),
  -- },
  -- cursor movement --
  -- { key = "LeftArrow", mods = mod.SUPER, action = act.SendString("\u{1b}OH") },
  -- { key = "RightArrow", mods = mod.SUPER, action = act.SendString("\u{1b}OF") },
  -- { key = "Backspace", mods = mod.SUPER, action = act.SendString("\u{15}") },
  -- copy/paste --
  { key = "c", mods = "CTRL|SHIFT", action = act.CopyTo("Clipboard") },
  { key = "v", mods = "CTRL|SHIFT", action = act.PasteFrom("Clipboard") },
  -- tabs --
  -- tabs: spawn+close
  -- { key = "t", mods = mod.SUPER, action = act.SpawnTab("DefaultDomain") },
  -- { key = "t", mods = mod.SUPER_REV, action = act.SpawnTab({ DomainName = "WSL:Ubuntu" }) },
  { key = "t", mods = mod.SUPER_REV, action = act.CloseCurrentTab({ confirm = false }) },
  -- tabs: navigation
  { key = "[", mods = mod.SUPER_REV, action = act.ActivateTabRelative(-1) },
  { key = "]", mods = mod.SUPER_REV, action = act.ActivateTabRelative(1) },
  -- { key = ",", mods = mod.SUPER_REV, action = act.MoveTabRelative(-1) },
  -- { key = ".", mods = mod.SUPER_REV, action = act.MoveTabRelative(1) },
  -- tab: title
  -- { key = "0", mods = mod.SUPER, action = act.EmitEvent("tabs.manual-update-tab-title") },
  -- { key = "0", mods = mod.SUPER_REV, action = act.EmitEvent("tabs.reset-tab-title") },
  -- tab: hide tab-bar
  -- { key = "9", mods = mod.SUPER, action = act.EmitEvent("tabs.toggle-tab-bar") },
  -- window --
  -- window: spawn windows
  -- { key = "n", mods = mod.SUPER, action = act.SpawnWindow }, -- window: zoom window
  -- {
  --   key = "-",
  --   mods = mod.SUPER,
  --   action = wezterm.action_callback(function(window, _pane)
  --     local dimensions = window:get_dimensions()
  --     if dimensions.is_full_screen then
  --       return
  --     end
  --     local new_width = dimensions.pixel_width - 50
  --     local new_height = dimensions.pixel_height - 50
  --     window:set_inner_size(new_width, new_height)
  --   end),
  -- },
  -- {
  --   key = "=",
  --   mods = mod.SUPER,
  --   action = wezterm.action_callback(function(window, _pane)
  --     local dimensions = window:get_dimensions()
  --     if dimensions.is_full_screen then
  --       return
  --     end
  --     local new_width = dimensions.pixel_width + 50
  --     local new_height = dimensions.pixel_height + 50
  --     window:set_inner_size(new_width, new_height)
  --   end),
  -- },
  -- panes --
  -- panes: split panes
  { key = [[\]], mods = mod.SUPER, action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
  { key = [[\]], mods = mod.SUPER_REV, action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
  -- panes: zoom+close pane
  -- { key = "Enter", mods = mod.SUPER, action = act.TogglePaneZoomState },
  { key = "p", mods = mod.SUPER_REV, action = act.CloseCurrentPane({ confirm = false }) },
  -- panes: navigation
  -- { key = "k", mods = "CTRL", action = act.ActivatePaneDirection("Up") },
  -- { key = "j", mods = "CTRL", action = act.ActivatePaneDirection("Down") },
  -- { key = "h", mods = "CTRL", action = act.ActivatePaneDirection("Left") },
  -- { key = "l", mods = "CTRL", action = act.ActivatePaneDirection("Right") },
  -- {
  --   key = "p",
  --   mods = mod.SUPER_REV,
  --   action = act.PaneSelect({ alphabet = "1234567890", mode = "SwapWithActiveKeepFocus" }),
  -- },
  -- panes: scroll pane
  -- { key = "u", mods = mod.SUPER, action = act.ScrollByLine(-5) },
  -- { key = "d", mods = mod.SUPER, action = act.ScrollByLine(5) },
  -- { key = "PageUp", mods = "NONE", action = act.ScrollByPage(-0.75) },
  -- { key = "PageDown", mods = "NONE", action = act.ScrollByPage(0.75) },
  -- key-tables --
  -- resizes fonts
  {
    key = "f",
    mods = "LEADER",
    action = act.ActivateKeyTable({ name = "resize_font", one_shot = false, timemout_miliseconds = 1000 }),
  },
  -- resize panes
  {
    key = "p",
    mods = "LEADER",
    action = act.ActivateKeyTable({ name = "resize_pane", one_shot = false, timemout_miliseconds = 1000 }),
  },
}

local key_tables = {
  resize_font = {
    { key = "k", action = act.IncreaseFontSize },
    { key = "j", action = act.DecreaseFontSize },
    { key = "r", action = act.ResetFontSize },
    { key = "Escape", action = "PopKeyTable" },
    { key = "q", action = "PopKeyTable" },
  },
  resize_pane = {
    { key = "k", action = act.AdjustPaneSize({ "Up", 1 }) },
    { key = "j", action = act.AdjustPaneSize({ "Down", 1 }) },
    { key = "h", action = act.AdjustPaneSize({ "Left", 1 }) },
    { key = "l", action = act.AdjustPaneSize({ "Right", 1 }) },
    { key = "Escape", action = "PopKeyTable" },
    { key = "q", action = "PopKeyTable" },
  },
}

local mouse_bindings = { -- Ctrl-click will open the link under the mouse cursor
  {
    event = { Up = { streak = 1, button = "Left" } },
    mods = "CTRL",
    action = act.OpenLinkAtMouseCursor,
  },
}

return {
  disable_default_key_bindings = true,
  -- disable_default_mouse_bindings = true,
  leader = { key = "Space", mods = mod.SUPER_REV },
  keys = keys,
  key_tables = key_tables,
  mouse_bindings = mouse_bindings,
}
