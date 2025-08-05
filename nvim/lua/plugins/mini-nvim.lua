return {
  "echasnovski/mini.nvim",
  version = false, -- 如果你想用最新版，false 表示不固定版本
  config = function()
    -- 启用 mini.ai 模块
    require("mini.ai").setup() -- 识别小/中/大括号
    require('mini.surround').setup({
      mappings = {
        add = 'ys',            -- 添加包围
        delete = 'yd',         -- 删除包围
        replace = 'yr',        -- 替换包围
        find = 'yf',           -- 查找包围
        find_left = 'yF',      -- 查找左侧包围
        highlight = 'yh',      -- 高亮包围
        update_n_lines = 'yn', -- 更新换行
      }
    })
    require('mini.indentscope').setup()
    -- require('mini.statusline').setup()
    -- require('mini.tabline').setup()


  end,
}
