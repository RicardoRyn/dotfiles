local wezterm = require("wezterm")

local config = {
  default_prog = { "C:/Users/RicardoRyn/scoop/apps/nu/current/nu.exe" },
  font = wezterm.font("Maple Mono NF CN"),
  font_size = 10,
  color_scheme = "catppuccin-latte",
  hide_tab_bar_if_only_one_tab = true,
  use_fancy_tab_bar = true,
}

return config
