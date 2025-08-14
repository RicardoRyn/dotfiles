if vim.g.vscode then
  return {}
else
  return {
    "nvimdev/dashboard-nvim",
    event = "VimEnter",
    dependencies = { { "nvim-tree/nvim-web-devicons" } },
    config = function()
      local logo = [[
          ██████╗ ██╗ ██████╗ █████╗ ██████╗ ██████╗  ██████╗     ██████╗ ██╗   ██╗███╗   ██╗
          ██╔══██╗██║██╔════╝██╔══██╗██╔══██╗██╔══██╗██╔═══██╗    ██╔══██╗╚██╗ ██╔╝████╗  ██║
          ██████╔╝██║██║     ███████║██████╔╝██║  ██║██║   ██║    ██████╔╝ ╚████╔╝ ██╔██╗ ██║
          ██╔══██╗██║██║     ██╔══██║██╔══██╗██║  ██║██║   ██║    ██╔══██╗  ╚██╔╝  ██║╚██╗██║
          ██║  ██║██║╚██████╗██║  ██║██║  ██║██████╔╝╚██████╔╝    ██║  ██║   ██║   ██║ ╚████║
          ╚═╝  ╚═╝╚═╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝  ╚═════╝     ╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═══╝
      ]]
      logo = string.rep("\n", 13) .. logo .. "\n\n"

      -- stylua: ignore
      local actions = {
        new_file = "ene | startinsert",
        find_file = function() require("telescope.builtin").find_files() end,
        find_text = function() require("telescope.builtin").live_grep() end,
        recent_files = function() require("telescope.builtin").oldfiles() end,
        restore_session = 'lua require("persistence").load()',
        quit = function() vim.api.nvim_input("<cmd>qa<cr>") end,
      }

      require("dashboard").setup({
        -- config
        theme = "doom",
        config = {
          header = vim.split(logo, "\n"),
          center = {
            { action = actions.new_file,        desc = " New File",        icon = " ", key = "n" },
            { action = actions.find_file,       desc = " Find File",       icon = " ", key = "f" },
            { action = actions.find_text,       desc = " Find Text",       icon = " ", key = "g" },
            { action = actions.recent_files,    desc = " Recent Files",    icon = " ", key = "r" },
            { action = actions.restore_session, desc = " Restore Session", icon = " ", key = "s" },
            { action = actions.quit,            desc = " Quit",            icon = " ", key = "q" },
          },
          footer = { "靡不有初 鲜克有终" },
        },
      })
    end,
  }
end
