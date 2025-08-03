if vim.g.vscode then
  return {}
else
  return {
    {
      "akinsho/bufferline.nvim",
      dependencies = {
        "nvim-tree/nvim-web-devicons",
        "famiu/bufdelete.nvim",
      },
      opts = {
        options = {
          diagnostics = "nvim_lsp",
          always_show_bufferline = true,
          diagnostics_indicator = function(_, _, diagnostics_dict)
            local indicator = "  "
            for level, number in pairs(diagnostics_dict) do
              local symbol
              if level == "error" then
                symbol = " "
              elseif level == "warning" then
                symbol = " "
              else
                symbol = " "
              end
              indicator = indicator .. number .. symbol
            end
            return indicator
          end,
          offsets = {
            {
              filetype = "neo-tree",
              text = "Neo-tree",
              highlight = "Directory",
              text_align = "left",
            },
            {
              filetype = "snacks_layout_box",
            },
          },
        },
      },
      keys = {
        { "<S-h>", ":BufferLineCyclePrev<CR>", silent = true },
        { "<S-l>", ":BufferLineCycleNext<CR>", silent = true },
        -- { "<leader>bd", ":bdelete<CR>", silent = true },
        {
          "<leader>bd",
          function()
            local buf = vim.api.nvim_get_current_buf()
            require("bufdelete").bufdelete(buf, false)
          end,
          desc = "Delete buffer without messing up window layout",
        },
        { "<leader>bo", ":BufferLineCloseOthers<CR>", silent = true },
        { "<leader>br", "<Cmd>BufferLineCloseRight<CR>", desc = "Delete Buffers to the Right" },
        { "<leader>bl", "<Cmd>BufferLineCloseLeft<CR>", desc = "Delete Buffers to the Left" },
        { "<leader>b<", "<cmd>BufferLineMovePrev<cr>", desc = "Move buffer prev" },
        { "<leader>b>", "<cmd>BufferLineMoveNext<cr>", desc = "Move buffer next" },
      },
      lazy = false,
    },
  }
end
