if vim.g.vscode then
  return {}
else
  return {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    opts = {
      indent = {
        char = "▏", -- 更细
        highlight = {
          "IndentLevel1",
          "IndentLevel2",
          "IndentLevel3",
          "IndentLevel4",
          "IndentLevel5",
          "IndentLevel6",
        },
      },
      scope = { enabled = false },
    },
    config = function(_, opts)
      local colors = {
        "#f4a8ab",
        "#f6d48f",
        "#a8caff",
        "#f6b084",
        "#b5e8b0",
        "#d8b4f8",
        "#a8e9f0",
      }
      for i, color in ipairs(colors) do
        vim.api.nvim_set_hl(0, "IndentLevel" .. i, { fg = color })
      end
      require("ibl").setup(opts)
    end,
  }
end
