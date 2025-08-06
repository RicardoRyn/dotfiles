if vim.g.vscode then
  return {}
else
  return {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.8",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      {
        "<leader>ff",
        function()
          require("telescope.builtin").find_files()
        end,
        desc = "Find Files (root dir)",
      },
      {
        "<leader>fr",
        function()
          require("telescope.builtin").oldfiles()
        end,
        desc = "Find Files (recently opened)",
      },
      {
        "<leader>fg",
        function()
          require("telescope.builtin").live_grep()
        end,
        desc = "Find Live Grep",
      },
      {
        "<leader>fb",
        function()
          require("telescope.builtin").buffers()
        end,
        desc = "Find Files (buffers)",
      },
      {
        "<leader>fh",
        function()
          require("telescope.builtin").help_tags()
        end,
        desc = "Find Help Tags",
      },
      -- Todo-comments
      {
        "<leader>ftt",
        function()
          local cwd = vim.fn.expand("%:p:h") -- 当前 buffer 所在目录
          vim.cmd("TodoTelescope cwd=" .. cwd)
        end,
        desc = "Find TODOs (cwd)",
      },
      {
        "<leader>ftT",
        "<cmd>TodoTelescope<CR>",
        desc = "Find TODOs (root dir)",
      },
      {
        "<leader>ftf",
        function()
          local cwd = vim.fn.expand("%:p:h") -- 当前 buffer 所在目录
          vim.cmd("TodoTelescope keywords=FIX,TODO,HACK,WARN cwd=" .. cwd)
        end,
        desc = "Find FIXs (cwd)",
      },
      {
        "<leader>ftF",
        "<cmd>TodoTelescope keywords=FIX,TODO,HACK,WARN<CR>",
        desc = "Find FIXs (root dir)",
      },
    },
  }
end
