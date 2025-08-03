return {
  "gbprod/yanky.nvim",
  opts = {
    picker = {
      select = {
        -- 修复yank位置在光标前的bug
        action = function(...)
          vim.cmd("normal! l")
          require("yanky.picker").actions.put("p")(...)
        end,
      },
    },
  },
}

