require("config.lazy")
require("config.keymaps")
require("config.options")
require("config.autocmds")

if not vim.g.vscode then
  require("config.lsp")
  require("config.lsp.lua")
  require("config.lsp.python")
end

--TODO: github上修改release的信息
--TODO: 统一标签命名
