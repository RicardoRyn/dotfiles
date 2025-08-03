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
    opts = {},

    config = function(_, opts)
      require("mason").setup(opts)
      local registry = require("mason-registry")

      -- 安装函数
      local function setup(name, config)
        local success1, package = pcall(registry.get_package, name)

        if success1 and not package:is_installed() then
          package:install()
        end

        -- 告诉 Neovim 的 LSP 客户端，你的编辑器支持哪些功能，特别是与补全（completion）相关的功能 (建议)
        config.capabilities = require("blink.cmp").get_lsp_capabilities()
        config.on_attach = function(client)
          -- 禁止LSP提供格式化能力，后面统一由none-ls来执行此功能
          client.server_capabilities.documentFormattingProvider = false
          client.server_capabilities.documentRangeFormattingProvider = false
        end

        -- 通过mason-lspconfig.nvim插件，获取对应mason LSP的nvim-lspconfig的LSP的名字
        local nvim_lsp = require("mason-lspconfig").get_mappings().package_to_lspconfig[name]
        local success2, err = pcall(function()
          vim.lsp.config(nvim_lsp, config)
        end)
        if not success2 then
        end
      end

      -- 定义需要安装的LSP
      local servers = {
        -- lua
        ["lua-language-server"] = {
          root_dir = function(bufnr, on_dir)
            local fname = vim.api.nvim_buf_get_name(bufnr)
            local root = require("lspconfig.util").root_pattern(
              ".git",
              "init.lua",
              ".luarc.json",
              ".luarc.jsonc",
              ".luacheckrc",
              ".stylua.toml",
              "stylua.toml",
              "selene.toml",
              "selene.yml"
            )(fname) or vim.fn.getcwd()
            on_dir(root)
          end,
          settings = {
            Lua = {
              diagnostics = {
                globals = { "vim" },
              },
            },
          },
        },

        -- python
        ["pyright"] = {},
      }

      -- 遍历使用安装函数安装指定 LSP
      for server, config in pairs(servers) do
        setup(server, config)
      end

      -- 初开nvim，手动执行LspStart
      local success3, _ = pcall(function()
        vim.cmd("LspStart") -- 由于mason为VeryLazy，需要手动启动一次
      end)

      -- 全局诊断配置
      vim.diagnostic.config({
        underline = true,
        virtual_text = true,
        update_in_insert = true,
        severity_sort = true,
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = "",
            [vim.diagnostic.severity.WARN] = "",
            [vim.diagnostic.severity.INFO] = "",
            [vim.diagnostic.severity.HINT] = "",
          },
          numhl = {
            [vim.diagnostic.severity.ERROR] = "DiagnosticError",
            [vim.diagnostic.severity.WARN] = "DiagnosticWarn",
            [vim.diagnostic.severity.INFO] = "DiagnosticInfo",
            [vim.diagnostic.severity.HINT] = "DiagnosticHint",
          },
        },
      })
    end,
  }
end
