th.git = th.git or {}
th.git.modified_sign = "󰏭 "
th.git.added_sign = "󰜄 "
th.git.untracked_sign = " "
th.git.ignored_sign = " "
th.git.deleted_sign = "󰛲 "
th.git.updated_sign = " "
require("git"):setup({ order = 0 })
require("full-border"):setup()
require("starship"):setup()
-- cloese preview panel when start yazi
require("toggle-pane"):entry("min-preview")

function Linemode:size_and_mtime()
  -- 1. 获取修改时间戳
  local time = math.floor(self._file.cha.mtime or 0)
  local time_str = ""
  if time ~= 0 then
    -- 2. 手动定义英文月份缩写，避免 os.date("%b") 产生的中文乱码
    local months = {
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    }
    -- 3. 解析时间成分
    local t = os.date("*t", time) -- 返回包含 year, month, day, hour, min 等的表
    local current_year = os.date("%Y")
    -- 4. 构建时间字符串
    if tostring(t.year) == current_year then
      -- 今年的文件：显示 "月 日 时:分" (例如：Oct 02 16:42)
      time_str = string.format("%s %02d %02d:%02d", months[t.month], t.day, t.hour, t.min)
    else
      -- 往年的文件：显示 "月 日  年份" (例如：Oct 02  2025)
      time_str = string.format("%s %02d  %d", months[t.month], t.day, t.year)
    end
  end
  -- 5. 获取文件大小
  local size = self._file:size()
  local size_str = size and ya.readable_size(size) or "-"
  -- 6. 返回最终格式
  return string.format("%s    %s", size_str, time_str)
end
