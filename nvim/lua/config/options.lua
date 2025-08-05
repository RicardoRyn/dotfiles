vim.g.mapleader = " "
vim.g.maplocalleader = "\\"
vim.g.autoformat = false

vim.opt.number = true
vim.opt.wrap = true
vim.opt.colorcolumn = "120"
vim.opt.timeoutlen = 1000
vim.opt.list = true
vim.opt.listchars = { tab = ">-", trail = "-" }
vim.opt.relativenumber = false
vim.opt.clipboard = "" -- 禁止neovim寄存器和系统剪贴板共用
vim.opt.conceallevel = 0 -- 不隐藏任何文本

vim.opt.ignorecase = true -- 如果输入没有大写，则大小写不敏感
vim.opt.smartcase = true -- 如果输入有大写，则大小写敏感

vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.smartindent = true

vim.opt.shell = "nu"
vim.opt.shellcmdflag = "-c"
vim.opt.shellquote = '"'
vim.opt.shellxquote = ""

vim.o.signcolumn = "yes"  -- 行号旁边留出显示标识符的位置

-- 关于neovide
if vim.g.neovide then
  -- Put anything you want to happen only in Neovide here
  -- vim.g.neovide_title_background_color =
  --   string.format("%x", vim.api.nvim_get_hl(0, { id = vim.api.nvim_get_hl_id_by_name("Normal") }).bg)
  vim.g.neovide_title_background_color = "#ffffff"
  vim.g.neovide_title_text_color = "#58913d" -- 设置窗口标签的“Neovide”的颜色
  vim.o.guifont = "Maple Mono NF CN:h12" -- neovide字体及其字体大小
  vim.g.neovide_scale_factor = 1.0 -- 界面字体缩放大小
  vim.g.neovide_floating_blur_amount_x = 2 -- 浮动窗口的模糊程度
  vim.g.neovide_floating_blur_amount_y = 2 -- 浮动窗口的模糊程度
  vim.g.neovide_floating_shadow = true
  vim.g.neovide_floating_z_height = 10
  vim.g.neovide_input_ime = true -- 支持中文输入法
  vim.g.neovide_light_angle_degrees = 45 -- 模拟光照角度45度，为部分元素增加视觉效果
  vim.g.neovide_light_radius = 5 -- 设置光照半径为5
  vim.g.neovide_opacity = 1 -- 透明程度，作用于整个窗口
  vim.g.neovide_normal_opacity = 1 -- 透明程度，仅影响普通文本背景
  vim.g.neovide_hide_mouse_when_typing = true -- 打字时，隐藏鼠标
  vim.g.neovide_refresh_rate = 240 -- 刷新率
  vim.g.neovide_refresh_rate_idle = 5 -- 空闲刷新率
  vim.g.neovide_fullscreen = false -- 全屏 end
  vim.g.neovide_profiler = false -- 左上角会显示一个小的帧数图
  vim.g.neovide_cursor_vfx_mode = "pixiedust"
  vim.g.neovide_cursor_vfx_particle_density = 17.0
end

