vim.lsp.config("*", {
  capabilities = require("blink.cmp").get_lsp_capabilities(),
  root_markers = { '.git' },
})

-- UI
vim.diagnostic.config({
  underline = true,
  virtual_text = true,
  update_in_insert = true,
  severity_sort = true,
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "",
      [vim.diagnostic.severity.WARN] = "",
      [vim.diagnostic.severity.INFO] = "",
      [vim.diagnostic.severity.HINT] = "",
    },
    numhl = {
      [vim.diagnostic.severity.ERROR] = "DiagnosticError",
      [vim.diagnostic.severity.WARN] = "DiagnosticWarn",
      [vim.diagnostic.severity.INFO] = "DiagnosticInfo",
      [vim.diagnostic.severity.HINT] = "DiagnosticHint",
    },
  },
})

-- 功能
vim.keymap.set("n", "<leader>cf", vim.lsp.buf.format, { desc = "Code format" })
vim.keymap.set("n", "<leader>cr", vim.lsp.buf.rename, { desc = "Rename symbol" })
vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "Code actions" })
-- 跳转
vim.keymap.set("n", "gd", ":Telescope lsp_definitions<CR>", { desc = "Go to definition" })
vim.keymap.set("n", "gD", vim.lsp.buf.declaration, { desc = "Go to declaration" })
vim.keymap.set("n", "gr", ":Telescope lsp_references<CR>", { desc = "Go to references" })
vim.keymap.set("n", "gt", ":Telescope lsp_type_definitions<CR>", { desc = "Go to type definition" })
vim.keymap.set("n", "gi", ":Telescope lsp_implementations<CR>", { desc = "Go to implementation" })
-- 诊断
vim.keymap.set("n", "<leader>uD", ":Telescope diagnostics bufnr=0<CR>", { desc = "Show diagnostics for current buffer" })
vim.keymap.set("n", "<leader>ud", vim.diagnostic.open_float, { desc = "Show line diagnostics" })
-- 提示
vim.keymap.set("n", "K", vim.lsp.buf.hover, { desc = "Show hover information" })
vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, { desc = "Show signature help" })
