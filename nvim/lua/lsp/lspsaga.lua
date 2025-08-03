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
    { "<leader>cr", ":Lspsaga rename<CR>", { desc = "Last Tab" } },
    { "<leader>cR", ":Lspsaga finder<CR>" },
    { "<leader>ch", ":Lspsaga hover_doc<CR>" },

    { "<leader>cd", ":Lspsaga goto_definition<CR>" },
    { "<leader>cc", ":Lspsaga code_action<CR>" },

    { "<leader>cn", ":Lspsaga diagnostic_jump_next<CR>" },
    { "<leader>cp", ":Lspsaga diagnostic_jump_prev<CR>" },
  },
}
