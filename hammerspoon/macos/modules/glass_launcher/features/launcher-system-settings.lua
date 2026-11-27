local settings = {}
-- Pane identifiers follow the Alfred System Settings workflow and macOS bundles.
local panes = {
    { "Wi-Fi", "无线网络 无线 局域网 wifi wlan", "com.apple.wifi-settings-extension", "wifi" },
    { "Bluetooth", "蓝牙 bt", "com.apple.BluetoothSettings", "antenna.radiowaves.left.and.right" },
    { "Network", "网络 以太网 ethernet dns proxy 代理", "com.apple.Network-Settings.extension", "network" },
    { "VPN", "虚拟专用网络", "com.apple.NetworkExtensionSettingsUI.NESettingsUIExtension", "lock.shield" },
    { "AirDrop & Handoff", "隔空投送 接力 airdrop handoff", "com.apple.AirDrop-Handoff-Settings.extension", "dot.radiowaves.left.and.right" },
    { "General", "通用", "com.apple.systempreferences.GeneralSettings", "gearshape" },
    { "About", "关于本机 关于这台 Mac 设备信息", "com.apple.SystemProfiler.AboutExtension", "laptopcomputer" },
    { "Software Update", "软件更新 系统更新 更新 update", "com.apple.Software-Update-Settings.extension", "arrow.clockwise" },
    { "Storage", "储存空间 存储空间 磁盘 disk", "com.apple.settings.Storage", "internaldrive" },
    { "Appearance", "外观 深色模式 dark mode", "com.apple.Appearance-Settings.extension", "circle.lefthalf.filled" },
    { "Desktop & Dock", "桌面 程序坞 dock stage manager 台前调度", "com.apple.Desktop-Settings.extension", "dock.rectangle" },
    { "Displays", "显示器 屏幕 分辨率 monitor display resolution", "com.apple.Displays-Settings.extension", "display" },
    { "Wallpaper", "墙纸 壁纸 桌面背景 background", "com.apple.Wallpaper-Settings.extension", "photo" },
    { "Screen Saver", "屏幕保护程序 屏保 screensaver", "com.apple.ScreenSaver-Settings.extension", "sparkles.tv" },
    { "Sound", "声音 音量 麦克风 扬声器 audio volume microphone", "com.apple.Sound-Settings.extension", "speaker.wave.2" },
    { "Keyboard", "键盘 输入法 键盘快捷键 input source shortcuts", "com.apple.Keyboard-Settings.extension", "keyboard" },
    { "Trackpad", "触控板 触摸板 手势 gesture", "com.apple.Trackpad-Settings.extension", "rectangle.and.hand.point.up.left" },
    { "Mouse", "鼠标", "com.apple.Mouse-Settings.extension", "computermouse" },
    { "Battery", "电池 电量 电源 power", "com.apple.Battery-Settings.extension*BatteryPreferences", "battery.100" },
    { "Notifications", "通知", "com.apple.Notifications-Settings.extension", "bell" },
    { "Control Center", "控制中心 菜单栏 control centre menu bar", "com.apple.ControlCenter-Settings.extension", "slider.horizontal.3" },
    { "Focus", "专注模式 勿扰 do not disturb", "com.apple.Focus-Settings.extension", "moon" },
    { "Privacy & Security", "隐私与安全性 隐私 安全性 privacy security", "com.apple.settings.PrivacySecurity.extension", "lock.shield" },
    { "Accessibility", "辅助功能 无障碍 voiceover", "com.apple.Accessibility-Settings.extension", "accessibility" },
    { "Screen Time", "屏幕使用时间", "com.apple.Screen-Time-Settings.extension", "hourglass" },
    { "Lock Screen", "锁定屏幕 锁屏", "com.apple.Lock-Screen-Settings.extension", "lock" },
    { "Touch ID & Password", "触控 ID 指纹 密码 touchid", "com.apple.Touch-ID-Settings.extension*TouchIDPasswordPrefs", "touchid" },
    { "AutoFill & Passwords", "自动填充 密码 autofill passwords", "com.apple.Passwords-Settings.extension", "key" },
    { "Apple Account", "苹果账户 Apple ID", "com.apple.systempreferences.AppleIDSettings*AppleIDSettings", "person.crop.circle" },
    { "iCloud", "云盘 云服务", "com.apple.systempreferences.AppleIDSettings:icloud", "icloud" },
    { "Internet Accounts", "互联网账户 邮件账户", "com.apple.Internet-Accounts-Settings.extension", "at" },
    { "Family", "家人共享 家庭共享 family sharing", "com.apple.Family-Settings.extension*Family", "person.2" },
    { "Users & Groups", "用户与群组 用户 账户 users groups", "com.apple.Users-Groups-Settings.extension", "person.2" },
    { "Login Items & Extensions", "登录项 启动项 扩展 login items startup apps", "com.apple.LoginItems-Settings.extension", "app.badge" },
    { "Device Management", "设备管理 描述文件 profiles mdm", "com.apple.Profiles-Settings.extension", "gearshape" },
    { "Language & Region", "语言与地区 语言 地区 locale", "com.apple.Localization-Settings.extension", "globe" },
    { "Date & Time", "日期与时间 时区 timezone", "com.apple.Date-Time-Settings.extension", "clock" },
    { "Sharing", "共享 文件共享 屏幕共享 file sharing screen sharing", "com.apple.Sharing-Settings.extension", "square.and.arrow.up" },
    { "Printers & Scanners", "打印机与扫描仪 打印机 扫描仪 printer scanner", "com.apple.Print-Scan-Settings.extension", "printer" },
    { "Spotlight", "聚焦搜索 聚焦 spotlight search", "com.apple.Spotlight-Settings.extension", "magnifyingglass" },
    { "Time Machine", "时间机器 时间胶囊 备份 backup", "com.apple.Time-Machine-Settings.extension", "clock.arrow.circlepath" },
    { "Startup Disk", "启动磁盘", "com.apple.Startup-Disk-Settings.extension", "externaldrive" },
    { "Transfer or Reset", "传输或还原 迁移 重置 reset migration", "com.apple.Transfer-Reset-Settings.extension", "arrow.left.arrow.right" },
    { "Apple Intelligence & Siri", "苹果智能 siri 人工智能", "com.apple.Siri-Settings.extension*siri-sae", "sparkles" },
    { "Wallet & Apple Pay", "钱包 支付 wallet apple pay", "com.apple.WalletSettingsExtension", "wallet.pass" },
    { "AppleCare & Warranty", "保修 保修服务 applecare warranty", "com.apple.Coverage-Settings.extension", "checkmark.shield" },
    { "Game Center", "游戏中心 game centre", "com.apple.Game-Center-Settings.extension", "gamecontroller" },
    { "Game Controllers", "游戏手柄 游戏控制器 controller", "com.apple.Game-Controller-Settings.extension", "gamecontroller.fill" },
}

local iconColors = {
    ["Wi-Fi"] = 0x167AEB, Bluetooth = 0x167AEB, Network = 0x3866D6, VPN = 0x3488B9,
    ["AirDrop & Handoff"] = 0x008CCB, Displays = 0x1688D8, Wallpaper = 0x2F9DCA,
    ["Screen Saver"] = 0x4265C4, Sound = 0xD84256, Battery = 0x289746,
    Notifications = 0xD84256, Focus = 0x6954C7, ["Privacy & Security"] = 0x1C79D2,
    Accessibility = 0x167AEB, ["Screen Time"] = 0x6954C7, ["Touch ID & Password"] = 0xD84256,
    ["AutoFill & Passwords"] = 0x7056BA, iCloud = 0x128FD1, ["Internet Accounts"] = 0x167AEB,
    Family = 0x5153BA, ["Users & Groups"] = 0x347CC7, ["Language & Region"] = 0x3178C8,
    Spotlight = 0x367BDD, ["Time Machine"] = 0x1E947F, ["Apple Intelligence & Siri"] = 0x8454BC,
    ["Game Center"] = 0xD6567A, ["Game Controllers"] = 0x4A67AD,
}

local function normalize(text)
    return (text:lower():gsub("[&%-]", " "):gsub("%s+", " "):match("^%s*(.-)%s*$"))
end

local function rank(title, aliases, query)
    if query == "" or title == query then return 1 end
    if (" " .. aliases .. " "):find(" " .. query .. " ", 1, true) then return 2 end
    if title:find(query, 1, true) == 1 then return 3 end
    local combined = title .. " " .. aliases
    for word in query:gmatch("%S+") do
        if not combined:find(word, 1, true) then return end
    end
    return 4
end

function settings.results(text, limit)
    local query = normalize(text)
    if limit and #query < 2 then return {} end
    local matches = {}
    for index, pane in ipairs(panes) do
        local score = rank(normalize(pane[1]), normalize(pane[2]), query)
        if score then matches[#matches + 1] = { pane = pane, score = score, index = index } end
    end
    table.sort(matches, function(a, b)
        if a.score ~= b.score then return a.score < b.score end
        return a.index < b.index
    end)
    local rows = {}
    for i = 1, math.min(#matches, limit or #matches) do
        local pane = matches[i].pane
        local chinese = pane[2]:match("^%S+")
        rows[i] = { title = pane[1], subtitle = "System Settings · " .. chinese,
                    symbol = pane[4], symbolTile = iconColors[pane[1]] or 0x777A83,
                    url = "x-apple.systempreferences:" .. pane[3] }
    end
    return rows
end

return settings
