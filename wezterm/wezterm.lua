-- local Config = require("config")
--
-- require("events.left-status").setup()
-- require("events.right-status").setup({ date_format = "%a %H:%M:%S" })
-- require("events.tab-title").setup({ hide_active_tab_unseen = false, unseen_icon = "circle" })
-- require("events.new-tab-button").setup()
--
-- return Config:init()
--   :append(require("config.appearance"))
--   :append(require("config.bindings"))
--   :append(require("config.domains"))
--   :append(require("config.fonts"))
--   :append(require("config.general"))
--   :append(require("config.launch"))
--   :append(require("config.layout")).options
local wezterm = require("wezterm")

local config = {
  default_prog = { "nu" },
  font = wezterm.font("Maple Mono NF CN"),
  font_size = 11,
  color_scheme = "catppuccin-latte",
  hide_tab_bar_if_only_one_tab = true,
  use_fancy_tab_bar = true,
}

return config
