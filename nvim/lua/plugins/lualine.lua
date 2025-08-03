if vim.g.vscode then
  return {}
else
  return {
    "nvim-lualine/lualine.nvim",
    opts = {},
  }
end
