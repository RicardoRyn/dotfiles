if vim.g.vscode then
  return {}
else
  return {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = {},
  }
end
