-- 禁用部分默认快捷键，防误触
vim.keymap.set({ "i" }, "jk", "<Esc>")

vim.keymap.set({ "n", "v" }, "J", "<Nop>")
vim.keymap.set({ "v" }, "U", "<Nop>")
vim.keymap.set({ "v" }, "u", "<Nop>")
vim.keymap.set("n", "<leader>h", "<cmd>:noh<cr>", { desc = "No highlight" })

vim.keymap.set("n", "j", "gj", { desc = "gj" })
vim.keymap.set("n", "k", "gk", { desc = "gk" })
vim.keymap.set("n", "gj", "j", { desc = "j" })
vim.keymap.set("n", "gk", "k", { desc = "k" })

vim.keymap.set("i", "<C-h>", "<ESC>I", { desc = "Move to the beginning of the line in Insert mode" })
vim.keymap.set("i", "<C-l>", "<ESC>A", { desc = "Move to the end of the line in Insert mode" })

vim.keymap.set("v", "<C-c>", '"+y') -- 让neovim中C-c可以复制内容到剪贴板
vim.keymap.set("i", "<C-v>", '<C-r>+', { noremap = true, silent = true, desc = "Paste from clipboard in insert mode" })

vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Go to Left Window", remap = true })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Go to Lower Window", remap = true })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Go to Upper Window", remap = true })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Go to Right Window", remap = true })

vim.keymap.set("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Increase Window Height" })
vim.keymap.set("n", "<C-Down>", "<cmd>resize -2<cr>", { desc = "Decrease Window Height" })
vim.keymap.set("n", "<C-Left>", "<cmd>vertical resize +2<cr>", { desc = "Decrease Window Width" })
vim.keymap.set("n", "<C-Right>", "<cmd>vertical resize -2<cr>", { desc = "Increase Window Width" })

