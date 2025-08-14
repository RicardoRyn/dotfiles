if vim.g.vscode then
  return {}
else
  return {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts_extend = { "spec" },
    opts = {
      preset = "helix",
      defaults = {},
      spec = {
      {
        mode = { "n", "v" },
        { "<leader>E", icon = { icon = "󰙅", color = "yellow" } },
        { "<leader>-", icon = { icon = "󰙅", color = "yellow" } },
        { "<leader>=", icon = { icon = "󰙅", color = "yellow" } },
        { "<leader>h", icon = { icon = "󰸱" } },

        { "<leader>a", group = "AI" },
        { "<leader>b", group = "Buffer" },
        { "<leader>c", group = "Code" },
        { "<leader>f", group = "Find" },
        { "<leader>ft", group = "Find Todo" },
        { "<leader>g", group = "Git" },
        { "<leader>u", group = "UI", icon = { icon = "󰙵 ", color = "cyan" } },
        { "<leader>v", group = "Virtual Env", icon = { icon = " ", color = "purple" } },
        { "<leader>x", group = "diagnostics/quickfix", icon = { icon = "󱖫 ", color = "green" } },
        { "g", group = "goto" },
        {
          "<leader>w",
          group = "Windows",
          proxy = "<c-w>",
          expand = function()
            return require("which-key.extras").expand.win()
          end,
        },
        { "<leader><space>", group = "Hop", icon = { icon = "󱔕" } },
        { "z", group = "fold" },
      },
    },
    },
    keys = {
      {
        "<c-w><space>",
        function()
          require("which-key").show({ keys = "<c-w>", loop = true })
        end,
        desc = "Window Hydra Mode (which-key)",
      },
      {
        "<leader>?",
        function()
          require("which-key").show({ global = false })
        end,
        desc = "Buffer Local Keymaps (which-key)",
      },
    },
  }
end
