-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

----------------------------------------------------------------------
---------------------- 一、nvim和vscode共用部分 ----------------------
----------------------------------------------------------------------

-- 禁用部分默认快捷键，防误触
vim.keymap.set({ "n", "v" }, "J", "<Nop>")
vim.keymap.set({ "v" }, "U", "<Nop>")
vim.keymap.set({ "v" }, "u", "<Nop>")
vim.keymap.set("n", "<leader>h", "<cmd>:noh<cr>", { desc = "No highlight" })
vim.keymap.del("n", "<leader>l", { desc = "Lazy" })
vim.keymap.del("n", "<leader>L", { desc = "LazyVim Changelog" })

----------------------------------------
----------- hop插件的快捷键 ------------
----------------------------------------
local hop = require("hop")
local directions = require("hop.hint").HintDirection
local positions = require("hop.hint").HintPosition
vim.keymap.set({ "n", "v" }, "<leader><leader>w", function()
  hop.hint_words({ direction = directions.AFTER_CURSOR, hint_position = positions.END })
end, { desc = "Go to next any begining of words" })
vim.keymap.set({ "n", "v" }, "<leader><leader>e", function()
  hop.hint_words({ direction = directions.AFTER_CURSOR })
end, { desc = "Go to next any end of words" })
vim.keymap.set({ "n", "v" }, "<leader><leader>b", function()
  -- hop.hint_words({ direction = directions.BEFORE_CURSOR })
  hop.hint_words({ direction = directions.BEFORE_CURSOR, hint_position = positions.END })
end, { desc = "Go to previous any begining of words" })
vim.keymap.set({ "n", "v" }, "<leader><leader>v", function()
  hop.hint_words({ direction = directions.BEFORE_CURSOR })
end, { desc = "Go to previous any end of words" })
vim.keymap.set({ "n", "v" }, "<leader><leader>l", function()
  hop.hint_camel_case({ direction = directions.AFTER_CURSOR, hint_position = positions.END })
end, { desc = "Go to next any begining of words" })
vim.keymap.set({ "n", "v" }, "<leader><leader>h", function()
  hop.hint_camel_case({ direction = directions.BEFORE_CURSOR, hint_position = positions.END })
end, { desc = "Go to previous any begining of words" })
vim.keymap.set({ "n", "v" }, "<leader><leader>j", function()
  hop.hint_lines({ direction = directions.AFTER_CURSOR })
end, { desc = "Go to line below" })
vim.keymap.set({ "n", "v" }, "<leader><leader>k", function()
  hop.hint_lines({ direction = directions.BEFORE_CURSOR })
end, { desc = "Go to line above" })

if not vim.g.vscode then
  ----------------------------------------------------------------------
  ---------------------- 二、仅在原生neovim中使用 ----------------------
  ----------------------------------------------------------------------

  -- 以下命令在vscode中不生效
  vim.keymap.set({ "i" }, "jk", "<Esc>")
  vim.keymap.set("n", "gj", "j", { desc = "j" })
  vim.keymap.set("n", "gk", "k", { desc = "k" })
  vim.keymap.set("v", "<C-c>", '"+y') -- 让neovim中C-c可以复制内容到剪贴板
  vim.keymap.set("n", "<leader>rn", ":IncRename ") -- 让nvim中更改变量名字
  vim.keymap.set("n", "<leader>rn", ":IncRename ") -- 让nvim中更改变量名字
  vim.keymap.set("i", "<C-h>", "<ESC>I", { desc = "Move to the beginning of the line in Insert mode" })
  vim.keymap.set("i", "<C-l>", "<ESC>A", { desc = "Move to the end of the line in Insert mode" })

  -- 以下命令在vscode中容易导致崩溃
  vim.keymap.set("n", "<leader>csv", "<cmd>CsvViewToggle<cr>", { desc = "CsvViewToggle" })
  -- 移动 buffer
  local moveBy = function(dir)
    if dir == "left" then
      dir = -1
    else
      dir = 1
    end
    local moveBy = vim.v.count
    if moveBy == 0 then
      moveBy = 1
    end
    local myBufferline = require("bufferline")
    for _ = 1, moveBy, 1 do
      myBufferline.move(dir)
    end
  end
  vim.keymap.set("n", "<b", function()
    moveBy("left")
  end, { desc = "Move current buffer to left" })
  vim.keymap.set("n", ">b", function()
    moveBy("right")
  end, { desc = "Move current buffer to right" })

  ----------------------------------------
  --------- multicursor快捷键 ------------
  ----------------------------------------
  local mc = require("multicursor-nvim")
  -- Add or skip cursor above/below the main cursor.
  vim.keymap.set({ "n", "x" }, "<up>", function()
    mc.lineAddCursor(-1)
  end, { desc = "Add multicursor above" })
  vim.keymap.set({ "n", "x" }, "<down>", function()
    mc.lineAddCursor(1)
  end, { desc = "Add multicursor blow" })
  vim.keymap.set({ "n", "x" }, "<leader><up>", function()
    mc.lineSkipCursor(-1)
  end, { desc = "Skip multicursor above" })
  vim.keymap.set({ "n", "x" }, "<leader><down>", function()
    mc.lineSkipCursor(1)
  end, { desc = "Skip multicursor blow" })
  -- Add or skip adding a new cursor by matching word/selection
  vim.keymap.set({ "n", "x" }, "<leader>n", function()
    mc.matchAddCursor(1)
  end, { desc = "Match then add multicursor next" })
  vim.keymap.set({ "n", "x" }, "<leader>s", function()
    mc.matchSkipCursor(1)
  end, { desc = "Match then skip multicursor next" })
  vim.keymap.set({ "n", "x" }, "<leader>N", function()
    mc.matchAddCursor(-1)
  end, { desc = "Match then add multicursor prev" })
  vim.keymap.set({ "n", "x" }, "<leader>S", function()
    mc.matchSkipCursor(-1)
  end, { desc = "Match then skip multicursor prev" })
  -- Add and remove cursors with control + left click.
  vim.keymap.set("n", "<c-leftmouse>", mc.handleMouse)
  vim.keymap.set("n", "<c-leftdrag>", mc.handleMouseDrag)
  vim.keymap.set("n", "<c-leftrelease>", mc.handleMouseRelease)
  -- Disable and enable cursors.
  vim.keymap.set({ "n", "x" }, "<c-q>", mc.toggleCursor, { desc = "" })
  -- Mappings defined in a keymap layer only apply when there are
  -- multiple cursors. This lets you have overlapping mappings.
  mc.addKeymapLayer(function(layerSet)
    -- Select a different cursor as the main one.
    layerSet({ "n", "x" }, "<left>", mc.prevCursor)
    layerSet({ "n", "x" }, "<right>", mc.nextCursor)
    -- Delete the main cursor.
    layerSet({ "n", "x" }, "<leader>x", mc.deleteCursor)
    -- Enable and clear cursors using escape.
    layerSet("n", "<esc>", function()
      if not mc.cursorsEnabled() then
        mc.enableCursors()
      else
        mc.clearCursors()
      end
    end)
  end)

else
  ----------------------------------------------------------------------
  ---------------------- 二、仅在vscode-neovim中使用 ----------------------
  ----------------------------------------------------------------------
  -- 取消这些映射，尽量保证vscode-neovim不会崩
  vim.keymap.del("n", "<leader>K", { desc = "Keywordprg" })
  vim.keymap.del("n", "<leader>n", { desc = "Notification History" })
  vim.keymap.del("n", "<leader>.", { desc = "Toggle Scratch Buffer" })
  vim.keymap.del("n", "<leader>`", { desc = "Switch to Other Buffer" })
  -- 常规快捷键，尽量与nvim本身保持一致，但是使用vscode的方式
  vim.api.nvim_exec2("nmap j gj", { output = false })
  vim.api.nvim_exec2("nmap k gk", { output = false })
  vim.keymap.set(
    "n",
    "<leader>qq",
    "<Cmd>lua require('vscode').call('workbench.action.closeWindow')<CR>",
    { desc = "Quit VSCode" }
  )
  vim.keymap.set("n", "u", "<Cmd>lua require('vscode').call('undo')<CR>", { desc = "Undo" })
  vim.keymap.set("n", "<C-r>", "<Cmd>lua require('vscode').call('redo')<CR>", { desc = "Redo" })
  -- 开关vscode中的侧栏
  vim.keymap.set(
    "n",
    "<leader>e",
    "<Cmd>lua require('vscode').call('workbench.action.toggleSidebarVisibility')<CR>",
    { desc = "toggleSidebarVisibility" }
  )
  vim.keymap.set(
    "n",
    "<leader>a",
    "<Cmd>lua require('vscode').call('workbench.action.toggleActivityBarVisibility')<CR>",
    { desc = "toggleActivityBarVisibility" }
  )
  vim.keymap.set(
    "v",
    "<leader>cf",
    "<Cmd>lua require('vscode').call('editor.action.formatSelection')<CR>",
    { desc = "format selection" }
  )
  vim.keymap.set(
    "n",
    "<leader>cf",
    "<Cmd>lua require('vscode').call('editor.action.formatDocument')<CR>",
    { desc = "format selection" }
  )
  -- yazi vscode
  vim.keymap.set("n", "<leader>-", "<Cmd>lua require('vscode').call('yazi-vscode.toggle')<CR>", { desc = "open yazi" })

end

----------------------------------------------------------------------
---------------------- 四、在原生neovide中使用 ----------------------
----------------------------------------------------------------------
if vim.g.neovide then
  -- 让neovide中 ctrl+c 可以复制内容到剪贴板
  vim.keymap.set("v", "<C-c>", '"+y')
  -- 让neovide中 ctrl+shift+v 可以粘贴剪贴板内容
  vim.keymap.set({ "n", "v", "s", "x", "o", "i", "l", "c", "t" }, "<C-S-v>", function()
    vim.api.nvim_paste(vim.fn.getreg("+"), true, -1)
  end, { noremap = true, silent = true })
end
