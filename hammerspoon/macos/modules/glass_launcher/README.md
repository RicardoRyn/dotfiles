# Glass Launcher

在 Hammerspoon 的根 `init.lua` 中加载：`require("modules.glass_launcher")`。

## 功能

### 搜索

- **应用与文件搜索**：直接输入名称启动 App 或用 Spotlight 找文件，如输入 `Safari`。
- **文件浏览**：输入 `~` 或 `/` 开头的路径逐层浏览，如输入 `/` 看根目录、输入 `~/Documents` 进文档目录。
- **正文搜索**：输入 `grep <关键词>` 在文档内容中查找。
- **词典**：输入 `define <词>` 或 `dict <词>` 查询释义，如 `define hello`。
- **直接打开网址**：输入完整 URL 或域名，如 `github.com`。
- **网页搜索**：输入关键字 + 空格 + 搜索词，如 `g hammerspoon`；可用 `g`、`gh`、`b`、`img`、`yt`、`maps`、`ddg`，无匹配时回退到默认搜索引擎。_（可扩展：改 [`config/launcher-web-searches.lua`](config/launcher-web-searches.lua)）_

### 计算与转换

- **计算器**：直接输入算式，如 `2*(3+4)`；支持四则运算、括号、幂和 `sqrt`/`abs`。
- **汇率换算**：输入 `<金额> <币种> to <币种>`，如 `100 usd to cny`。
- **颜色转换**：输入 Hex 或 RGB，如 `#ff0000` 或 `rgb(255, 0, 0)`，输出多种 CSS 与 NSColor/UIColor 表示。
- **翻译**：输入 `tl <文本>`，如 `tl hello`，可译成简体中文或英文。

### 系统控制

- **系统设置搜索**：输入 `settings <名称>` 或直接输入设置名（中英文均可），如 `settings wifi` 或 `蓝牙`。
- **系统操作**：输入关键字执行以下操作：
  - `screensaver` 启动屏保
  - `trash` 显示废纸篓
  - `emptytrash` 清空废纸篓（需确认）
  - `logout` 退出登录（需确认）
  - `sleep` 睡眠（需确认）
  - `sleepdisplays` 仅关闭显示器（需确认）
  - `lock` 锁屏（需确认）
  - `restart` 重启（需确认）
  - `shutdown` 关机（需确认）
- **存储与推出**：输入 `storage` 或 `存储空间` 查看各磁盘用量；输入 `eject` 列出并推出外接磁盘。
- **防睡眠**：输入 `caffeine` 或 `咖啡因` 开启/关闭防止空闲睡眠。
- **外观切换**：输入 `theme` 在浅色/深色模式间切换。
- **重载配置**：输入 `reload`（或 `reload config`）重载 Hammerspoon。

### 剪贴板与动作

- **剪贴板历史**：按 `Cmd+Shift+V` 打开，搜索并选择历史项回填到当前应用；也可输入 `clear` 清空历史。
- **文件动作**：在 Finder 选中文件后按 `Option+X`，对文件执行复制路径、PDF 转 PNG、移除 EXIF （需要安装 exiftool `brew install exiftool`）等操作。_（可扩展：改 [`config/launcher-custom-actions.lua`](config/launcher-custom-actions.lua)）_
- **文本动作**：选中文本后按 `Option+X`，对文本执行字数统计、复制路径等自定义动作。_（可扩展：改 [`config/launcher-custom-actions.lua`](config/launcher-custom-actions.lua)）_
- **App 快速启动**：为常用 App 绑定快捷键。_（在 [`config/app-launchers.lua`](config/app-launchers.lua) 配置，默认无启用项）_

默认快捷键：`Ctrl+Space` 打开或关闭启动器，`Option+X` 对选中文本或 Finder 文件执行动作，`Cmd+Shift+V` 打开剪贴板历史。

| 想改什么       | 在哪里改                                                                                                                                                                  |
| -------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 全局快捷键     | [config/hotkeys.lua](config/hotkeys.lua)：修改对应入口的 `mods` 和 `key`。                                                                                                |
| 网页搜索       | [config/launcher-web-searches.lua](config/launcher-web-searches.lua)：设置关键字和含 `{query}` 的 URL。可选 `icon`（相对于 `assets/`）和 `fallback`（加入兜底搜索结果）。 |
| 文本或文件动作 | [config/launcher-custom-actions.lua](config/launcher-custom-actions.lua)：仿照现有 `actions.register(...)` 示例添加。                                                     |
| App 快速启动   | [config/app-launchers.lua](config/app-launchers.lua)：编辑共用修饰键，添加按键和 App 的 bundle ID。默认无启用项。                                                         |

例如，把 `launcher` 改成 `{ mods = { "ctrl", "alt" }, key = "l" }`，即可用 `Ctrl+Option+L` 打开启动器。请使用 Hammerspoon 键名，并从 `cmd`、`ctrl`、`alt`、`shift` 中选至少一个不冲突的组合。保存后重载 Hammerspoon。

## 重新编译

需要 Swift 编译器和 macOS 26 或更新版本的 SDK（由 Xcode 或 Command Line Tools 提供）。
从 Hammerspoon 配置目录运行：

```sh
cd modules/glass_launcher
./build.sh
```

脚本会更新 `assets/GlassLauncher.app` 和 `assets/launcher-define`。编译成功后重载 Hammerspoon。
