local gpu_adapters = require("utils.gpu-adapter")
local platform = require("utils.platform")
local max_fps = platform.is_win and 240 or 60
local tab_max_width = platform.is_win and 30 or 50

return {
  max_fps = max_fps,
  front_end = "WebGpu",
  webgpu_power_preference = "HighPerformance",
  webgpu_preferred_adapter = gpu_adapters:pick_best(),
  -- webgpu_preferred_adapter = gpu_adapters:pick_manual('Dx12', 'IntegratedGpu'),
  -- webgpu_preferred_adapter = gpu_adapters:pick_manual('Gl', 'Other'),
  underline_thickness = "1.5pt",

  -- cursor
  animation_fps = 144,
  cursor_blink_ease_in = "EaseOut",
  cursor_blink_ease_out = "EaseOut",
  default_cursor_style = "BlinkingBlock",
  cursor_blink_rate = 650,

  -- color scheme
  -- color_scheme = "tokyonight",
  color_scheme = "Catppuccin Latte",

  -- scrollbar
  enable_scroll_bar = true,

  -- tab bar
  enable_tab_bar = true,
  hide_tab_bar_if_only_one_tab = true,
  use_fancy_tab_bar = false,
  tab_max_width = tab_max_width,
  show_tab_index_in_tab_bar = false,
  switch_to_last_active_tab_when_closing_tab = true,

  -- window
  window_decorations = "INTEGRATED_BUTTONS | RESIZE",
  window_padding = { left = 3, right = 3, top = 0, bottom = 0 },
  adjust_window_size_when_changing_font_size = false,
  window_close_confirmation = "NeverPrompt",
  window_frame = {
    active_titlebar_bg = "#1a1b26",
    -- font = fonts.font,
    -- font_size = fonts.font_size,
  },
  inactive_pane_hsb = { saturation = 0.9, brightness = 0.3 },

  visual_bell = {
    fade_in_function = "EaseIn",
    fade_in_duration_ms = 250,
    fade_out_function = "EaseOut",
    fade_out_duration_ms = 250,
    target = "CursorColor",
  },
}
