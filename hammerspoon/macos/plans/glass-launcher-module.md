# 将 Glass Launcher 整理为独立模块

## Context

Glass Launcher 是从另一个项目引入的；它的 Lua 文件和原生资源目前散落在 `~/.hammerspoon` 根目录。将它们整体收进 `modules/glass_launcher/`，让个人模块依旧独立。本次按职责整理包内目录，将全局快捷键集中到配置目录，并补一份简短的自定义指南。保持默认行为，不拆分现有 Lua 文件。

## 现状盘点

迁移前有 4 处资源路径依赖配置根目录：

- `search-launcher.lua:7` 与 `launcher-clipboard.lua:11`：`hs.configdir .. "/GlassLauncher.app/Contents/MacOS/GlassLauncher"`
- `search-launcher.lua:246`：`hs.configdir .. "/launcher-define"`
- `search-launcher.lua:213`：`hs.configdir .. "/" .. provider.icon`，其中 `launcher-web-searches.lua` 里 icon 写作 `"fallback-icons/xxx.png"`

另有 14 处对旧模块名的 `require`，包括正文搜索的延迟加载和对 `universal-actions` 的引用。

三组全局快捷键目前都写在 `search-launcher.lua`：主启动器用 `hs.eventtap`，选中项动作和剪贴板历史用 `hs.hotkey.bind`。App 快速启动当前没有启用项，但其注册器写死了 `ctrl` 修饰键。

不受影响：`launcher-clipboard-state.lua` 的数据目录在 `~/Library/Application Support/`，与代码位置无关，剪贴板历史不丢。

已验证：Hammerspoon 的 `package.path` 含 `configdir/?/init.lua`，所以 `require("modules.glass_launcher")` 可以直接加载目录包的 `init.lua`。

## Approach

采用普通 Lua 目录包，按职责分一层。包根只保留加载入口和 README；保留上游文件名，方便对照。根 `init.lua` 的启动器区块缩为 `require("modules.glass_launcher")` 一行。

```text
modules/glass_launcher/
├── init.lua
├── README.md
├── core/                          # 启动器与资源路径
│   ├── search-launcher.lua
│   └── paths.lua
├── features/                      # 搜索、剪贴板及内置功能
│   ├── launcher-search-scope.lua
│   ├── launcher-content-search.lua
│   ├── launcher-clipboard.lua
│   ├── launcher-clipboard-state.lua
│   ├── launcher-calculator.lua
│   ├── launcher-colors.lua
│   ├── launcher-caffeine.lua
│   ├── launcher-system-actions.lua
│   └── launcher-system-settings.lua
├── actions/                       # 通用动作注册表和内置文件动作
│   ├── universal-actions.lua
│   └── launcher-file-conversions.lua
├── config/                        # 用户自定义入口
│   ├── hotkeys.lua
│   ├── app-launchers.lua
│   ├── launcher-custom-actions.lua
│   └── launcher-web-searches.lua
└── assets/
    ├── GlassLauncher.app/
    ├── launcher-define
    └── fallback-icons/
```

- 包内使用完整模块名，例如 `modules.glass_launcher.features.launcher-clipboard`。入口按原顺序加载核心、调用 `prewarm()`、加载 App 快捷键、注册文件转换、注册自定义动作，最后返回核心模块表。不增加子目录入口，不修改 `package.path`，不引入新配置框架。
- `core/paths.lua` 只提供一个路径表：`assets`、`helper` 和 `dictionary`。以 `hs.configdir .. "/modules/glass_launcher/assets"` 为基准，网页图标继续使用相对路径 `fallback-icons/...`。资源原样移动，不改签名、bundle ID 或持久化位置。

### 快捷键配置

`config/hotkeys.lua` 返回一张普通 Lua 表，三个入口都使用 `{ mods = {...}, key = "..." }`，默认值不变：

| 配置项 | 功能 | 默认值 |
|---|---|---|
| `launcher` | 打开或关闭主启动器 | `Ctrl+Space` |
| `selection` | 对选中文本或 Finder 文件执行动作 | `Option+S` |
| `clipboard` | 打开剪贴板历史 | `Cmd+Shift+V` |

核心在加载时读一次配置。主启动器保留现有 `hs.eventtap`，用 `hs.keycodes.map` 解析主键并用 `containExactly` 匹配修饰键，保留长按抑制、启动期输入缓冲和关窗逻辑；其余两个入口直接把配置传给现有 `hs.hotkey.bind`。三个入口允许修改主键和修饰键，使用 Hammerspoon 键名和 `cmd`、`ctrl`、`alt`、`shift`，至少指定一个修饰键并避免冲突。

可选的 App 快速启动在 `config/app-launchers.lua` 里同时编辑共用修饰键（默认 `ctrl`）和 App 键位。窗口内的 Esc、退格和用于读写剪贴板的系统复制／粘贴按键不属于全局入口，不纳入配置。

### README 内容

简短说明如何加载，列出三个全局入口的默认快捷键，并给一个示例（如 `launcher = { mods = { "ctrl", "alt" }, key = "l" }`），提示保存后重载。用表格指明在哪自定义：

| 想改什么 | 文件（相对包根） |
|---|---|
| 改启动器、选中项动作或剪贴板历史快捷键 | `config/hotkeys.lua`：编辑对应入口的 `mods` 与 `key`。 |
| 为 App 加快捷键 | `config/app-launchers.lua`：可改共用修饰键，取消注释或新增按键与 bundle ID；默认没有启用项。 |
| 增加网页搜索关键字 | `config/launcher-web-searches.lua`：改 `keyword`、含 `{query}` 的 URL，以及可选图标和 `fallback`。 |
| 添加文本或文件动作 | `config/launcher-custom-actions.lua`：参考已有 `actions.register(...)` 示例。 |

README 使用相对链接指向配置文件，不展开内部实现。

## Files to modify

- `init.lua`：只替换 Glass Launcher 加载区块；保留 IPC、两个个人模块和重载通知。
- 在 `modules/glass_launcher/` 新增 `init.lua`、`core/paths.lua`、`config/hotkeys.lua` 和 `README.md`。
- `core/search-launcher.lua`、`features/launcher-clipboard.lua`：修正内部依赖和资源路径；前者改为从配置读取三个全局快捷键。
- `config/app-launchers.lua`：将 App 快速启动的修饰键提为可编辑的局部配置，保留默认 `ctrl` 和空启用列表。
- `features/launcher-content-search.lua`、`actions/launcher-file-conversions.lua`、`config/launcher-custom-actions.lua`：迁移后修正内部依赖。
- 其余文件按目录树迁移，内容不变。

## Reuse

- 现有 `modules/` 的「返回 M 表」模块惯例（`modules/copy_bundle_id.lua`）
- `core/search-launcher.lua` 保留当前导出的 `prewarm`、热键和 `showFileActions` 等，入口直接复用。
- `actions/universal-actions.lua` 保留现有注册机制；核心、内置动作和自定义动作继续共用同一个注册表。

## Steps

- [x] 按目录树迁移启动器文件及资源，保留权限和 `.app` 包结构，不留根目录转发文件。
- [x] 改写内部 `require`，增加资源路径表并更新 4 处资源引用。
- [x] 把三个全局入口接到 `config/hotkeys.lua`，并让 App 启动器的共用修饰键可改。
- [x] 添加包入口，收敛根 `init.lua` 的加载逻辑，编写简短的 `README.md`。

## Verification

- [x] 静态检查根目录无残留启动器文件、包内无旧模块引用、README 链接指向实际配置文件；用 `test -x` 和 `codesign --verify` 检查移动后的两个 helper 和 `.app` 签名。
- [x] 在 Hammerspoon 执行 `hs.reload()`，确认控制台无加载或 helper 启动错误；重载后用 `hs -c 'print(package.loaded["modules.glass_launcher"] ~= nil)'` 确认入口已加载。
- [x] 使用 `Ctrl+Space` 检查应用搜索、网页图标（如 `g hammerspoon`）、词典定义（`define hello`）和文件的 `Copy Path` 动作；输入 `grep <已知关键词>` 验证正文搜索的延迟加载，用 `Option+S` 检查 `Count Characters` 自定义动作。
- [x] 使用 `Cmd+Shift+V` 确认重载前的剪贴板历史仍可见，并测试新复制的图片能进入历史（覆盖剪贴板自己的 helper 路径）。确认个人模块照常加载。
- [x] 暂时将三个全局快捷键改成未占用的组合（同时改主键和修饰键），重载后确认新键触发、旧键不再触发；检查主启动器仍支持开关、长按不重复触发、刚打开时立即输入。临时配置一个 App 验证自定义修饰键，再把两份配置恢复默认并重载。