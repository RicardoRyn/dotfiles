-- Mason + none-ls 用来代码格式化
-- none-ls相当也提供了一个LSP，但是我们只用这个LSP来进行格式化
return {
  "nvimtools/none-ls.nvim",
  depencies = {
    "nvim-lua/plenary.nvim",
  },
  event = "VeryLazy",
  config = function()
    local registry = require("mason-registry")
    local function setup(name)
      local success, package = pcall(registry.get_package, name)
      if success and not package:is_installed() then
        vim.notify(package.name .. ": 格式化器正在安装...", vim.log.levels.INFO)
        package:install()
      end
    end

    local servers = { "stylua" }
    for _, server in ipairs(servers) do
      setup(server)
    end

    local null_ls = require("null-ls")
    null_ls.setup({
      sources = {
        null_ls.builtins.formatting.stylua,
      },
    })
  end,
  keys = {
    { "<leader>cf", vim.lsp.buf.format },
  },
}
