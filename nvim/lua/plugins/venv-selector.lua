return {
  "linux-cultist/venv-selector.nvim",
  cond = function()
    return not vim.g.vscode
  end,
  dependencies = {
    -- "neovim/nvim-lspconfig",
    -- "mfussenegger/nvim-dap",
    -- "mfussenegger/nvim-dap-python", --optional
    { "nvim-telescope/telescope.nvim", branch = "0.1.x", dependencies = { "nvim-lua/plenary.nvim" } },
  },
  lazy = false,
  branch = "regexp", -- This is the regexp branch, use this for the new version
  keys = {
    { "<leader>v", "<cmd>VenvSelect<cr>", desc = "Virtual Env" },
  },
  opts = {
    -- Your settings go here
    search = {
      anaconda_base = {
        command = "fd python.exe$ E:/python/envs --max-depth 2 --full-path --color never",
        type = "anaconda", -- 这里必须是 anaconda，才能生效
      },
    },
  },
}
