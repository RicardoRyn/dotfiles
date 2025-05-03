--修复yanky粘贴位置在光标前的bug
if vim.g.vscode then
  return {}
else
  return {
    "gbprod/yanky.nvim",
    opts = {
      picker = {
        select = {
          -- fix put action
          action = function(...)
            vim.cmd("normal! l")
            require("yanky.picker").actions.put("p")(...)
          end,
        },
      },
    },
  }
end
