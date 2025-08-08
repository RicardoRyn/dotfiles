if vim.g.vscode then
  return {}
else
  return {
    "mason-org/mason.nvim",
    event = "VeryLazy",
    dependencies = {
      -- nvim-lspconfig的默认作用就是为各个LSP提供了一个默认的配置
      "neovim/nvim-lspconfig",
      -- 由于mason和nvim-lspconfig中LSP的名字并不完全一样，需要该插件来匹配
      "mason-org/mason-lspconfig.nvim",
    },
    opts = {
      ensure_installed = {
        "lua-language-server",
        "stylua",

        "pyright",
        "ruff",

        "bash-language-server",
        "shellcheck",
        "shfmt",
      }
    },
    config = function(_, opts)

      require("mason").setup(opts)
      local mr = require("mason-registry")
      local function ensure_installed()
        for _, tool in ipairs(opts.ensure_installed) do
          local p = mr.get_package(tool)
          if not p:is_installed() then
            p:install()
          end
        end
      end
      if mr.refresh then
        mr.refresh(ensure_installed)
      else
        ensure_installed()
      end
    end
  }
end
