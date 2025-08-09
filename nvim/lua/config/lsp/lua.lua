local util = require("lspconfig.util")

local function custom_root_dir(fname)
  return util.search_ancestors(fname, function(path)
    for _, marker in ipairs({
      ".git",
      "init.lua",
      ".luarc.json",
      ".luarc.jsonc",
      ".luacheckrc",
      ".stylua.toml",
      "stylua.toml",
      "selene.toml",
      "selene.yml",
    }) do
      if util.path.exists(util.path.join(path, marker)) then
        return path
      end
    end
  end) or vim.fn.getcwd()
end

vim.lsp.config("lua_ls", {
  root_dir = function(bufnr, on_dir)
    local fname = vim.api.nvim_buf_get_name(bufnr)
    local root = custom_root_dir(fname)
    on_dir(root)
  end,
  settings = {
    Lua = {
      diagnostics = {
        globals = { "vim" },
      },
    },
  },
  on_attach = function(client)
    client.server_capabilities.documentFormattingProvider = false
    client.server_capabilities.documentRangeFormattingProvider = false
  end,
})

vim.lsp.enable("lua_ls")
