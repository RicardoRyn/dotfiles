-- 设置主题
if vim.g.vscode then
  return {}
else
  return {
    -- add catppuccin
    {
      "catppuccin/nvim",
      name = "catppuccin",
      opts = {
        highlight_overrides = {
          latte = function(colors)
            return {
              CursorLine = { bg = "#dce0e8" }, -- 更浅的灰色背景
            }
          end,
        },
      },
    },

    -- Configure LazyVim to load catppuccin
    {
      "LazyVim/LazyVim",
      opts = {
        -- colorscheme = "tokyonight",
        colorscheme = "catppuccin-latte",
      },
    },
  }
end
