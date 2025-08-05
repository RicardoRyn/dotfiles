if vim.g.vscode then
  return {}
else
  return {
    {
      "catppuccin/nvim",
      name = "catppuccin",
      priority = 1000,

      lazy = false,
      config = function()
        require("catppuccin").setup({
          flavour = "latte",
          integrations = {
            -- 开启 bufferline 支持
            bufferline = true,
          },
        })

        vim.cmd.colorscheme("catppuccin")
        vim.cmd([[highlight CursorLine guibg=#dce0e8]])
        vim.o.cursorline = true
      end,
    },
    -- {
    --   "Mofiqul/vscode.nvim",
    --   priority = 1000,
    --   config = function()
    --     require("vscode").setup({
    --       style = "light", -- or "dark"
    --     })
    --     vim.cmd.colorscheme("vscode")
    --   end
    -- }
  }
end
