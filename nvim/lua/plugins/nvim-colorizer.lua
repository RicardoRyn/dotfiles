if vim.g.vscode then
  return {}
else
  return {
    "NvChad/nvim-colorizer.lua",
    event = "BufReadPre",
    config = function()
      require("colorizer").setup({
        filetypes = { "*" }, -- 所有文件类型都启用
        user_default_options = {
          names = true, -- 识别 color names (red, blue)
          rgb_fn = true, -- 识别 rgb(), rgba()
          hsl_fn = true, -- 识别 hsl(), hsla()
          tailwind = true, -- 支持 tailwind class 名称
          css = true, -- 在 css 中启用
          mode = "background", -- 或 "foreground"
        },
      })
    end,
  }
end
