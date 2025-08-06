require("config.lazy")
require("config.keymaps")
require("config.options")
require("config.autocmds")

if not vim.g.vscode then
  require("config.lsp")
  require("config.lsp.lua")
  require("config.lsp.python")
end

-- TODO: autocmd的名字改成ricardo
-- TODO: mini.icons还是没用上
