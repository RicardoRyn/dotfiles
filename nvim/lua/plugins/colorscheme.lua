if vim.g.vscode then
  return {}
else
  return {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    lazy = false,
    config = function()
      require("catppuccin").setup({
        flavour = "latte", -- latte | frappe | macchiato | mocha
        integrations = {
          bufferline = true, -- 开启 bufferline 支持
        },
      })

      vim.cmd.colorscheme("catppuccin")
    end,
  }
end
