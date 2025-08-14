if vim.g.vscode then
  return {}
else
  return {
    "quarto-dev/quarto-nvim",
    dependencies = {
      "jmbuhr/otter.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    ft = { "quarto", "markdown" },

    opts = {
      lspFeatures = {
        enabled = true,
        languages = { "lua", "python", "bash", "rust" },
        chunks = "all",
        diagnostics = {
          enabled = true,
          triggers = { "BufWritePost" },
        },
        completion = {
          enabled = true,
        },
      },
      keymap = {
        hover = "H",
        definition = "gd",
        rename = "<leader>rn",
        references = "gr",
        format = "<leader>gf",
      },
      codeRunner = {
        enabled = true,
        default_method = "molten",
      },
    },
    config = function()
      local runner = require("quarto.runner")
      vim.keymap.set("n", "<localleader>qc", runner.run_cell, { desc = "run cell", silent = true })
      vim.keymap.set("n", "<localleader>qa", runner.run_above, { desc = "run cell and above", silent = true })
      vim.keymap.set("n", "<localleader>qA", runner.run_all, { desc = "run all cells", silent = true })
      vim.keymap.set("n", "<localleader>ql", runner.run_line, { desc = "run line", silent = true })
      vim.keymap.set("v", "<localleader>q", runner.run_range, { desc = "run visual range", silent = true })
      vim.keymap.set("n", "<localleader>QA", function()
        runner.run_all(true)
      end, { desc = "run all cells of all languages", silent = true })
    end,
  }
end
