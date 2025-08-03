if vim.g.vscode then
  return {}
else
  return {
    "nvimdev/lspsaga.nvim",
    cmd = "Lspsaga",
    opts = {
      finder = {
        keys = {
          toggle_or_open = "<CR>",
        },
      },
    },
    keys = {
      { "<leader>cr", ":Lspsaga rename<CR>", desc = "Rename variable" },
      { "<leader>cR", ":Lspsaga finder<CR>", desc = "Find references" },
      { "<leader>ch", ":Lspsaga hover_doc<CR>", desc = "Show documentation" },

      { "<leader>cd", ":Lspsaga goto_definition<CR>", desc = "Go to definition" },
      { "<leader>cc", ":Lspsaga code_action<CR>", desc = "Code actions" },

      { "<leader>cn", ":Lspsaga diagnostic_jump_next<CR>", desc = "Jump to next diagnostic" },
      { "<leader>cp", ":Lspsaga diagnostic_jump_prev<CR>", desc = "Jump to previous diagnostic" },
    },
  }
end
