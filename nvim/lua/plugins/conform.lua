if vim.g.vscode then
  return {}
else
  return {
    "stevearc/conform.nvim",
    cmd = { "ConformInfo" }, -- 可选命令
    keys = {
      {
        "<leader>cf",
        function()
          require("conform").format({ async = true, lsp_fallback = false })
        end,
        desc = "Code Format",
      },
    },
    opts = {
      format_on_save = false,
      formatters_by_ft = {
        lua = { "stylua" },
        python = { "ruff_format" },
        bash = { "shfmt" },
      },
    },
  }
end
