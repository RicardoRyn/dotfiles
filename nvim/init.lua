require("config.lazy")
require("config.keymaps")
require("config.options")
require("config.autocmds")

if not vim.g.vscode then
  -- LSP
  require("config.lsp")
  require("config.lsp.lua")
  require("config.lsp.python")
  require("config.lsp.bash")

  -- snippets
  require("snippets.python")
  require("snippets.lua")
end

-- TODO: 在linux上使用安装kitty终端，然后使用molten.nvim
-- TODO: 使用codeium.nvim获得代码补全体验
