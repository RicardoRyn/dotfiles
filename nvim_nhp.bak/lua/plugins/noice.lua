-- 优化搜索框UI
if vim.g.vscode then
  return {}
else
  return {
    "folke/noice.nvim",
    event = "VeryLazy",
    opts = {
      presets = {
        bottom_search = false,
      },
    },
  }
end
