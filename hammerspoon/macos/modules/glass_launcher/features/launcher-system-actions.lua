local actions = {}

local commands = {
    screensaver = { title = "Screen Saver", symbol = "sparkles.tv", command = "/usr/bin/open", args = { "-a", "ScreenSaverEngine" } },
    trash = { title = "Show Trash", symbol = "trash", script = 'tell application "Finder"\nactivate\nopen trash\nend tell' },
    emptytrash = { title = "Empty Trash", symbol = "trash.slash", confirm = true, script = 'tell application "Finder" to empty trash' },
    logout = { title = "Log Out", symbol = "rectangle.portrait.and.arrow.right", confirm = true, script = 'tell application "System Events" to log out' },
    sleep = { title = "Sleep", symbol = "moon", confirm = true, power = "systemSleep" },
    sleepdisplays = { title = "Sleep Displays", symbol = "display", confirm = true, command = "/usr/bin/pmset", args = { "displaysleepnow" } },
    lock = { title = "Lock Screen", symbol = "lock", confirm = true, power = "lockScreen" },
    restart = { title = "Restart", symbol = "arrow.clockwise", confirm = true, script = 'tell application "System Events" to restart' },
    shutdown = { title = "Shut Down", symbol = "power", confirm = true, script = 'tell application "System Events" to shut down' },
}

function actions.result(keyword)
    local command = commands[keyword]
    if not command then return end
    return {
        title = command.title, symbol = command.symbol, action = "systemAction", systemCommand = command,
        subtitle = command.confirm and "Requires confirmation" or "System action",
    }
end

function actions.run(command)
    if command.power then
        hs.caffeinate[command.power]()
        return
    end
    local executable, arguments = command.command, command.args
    if command.script then
        executable, arguments = "/usr/bin/osascript", { "-e", command.script }
    end
    local function finish(code)
        if code ~= 0 then hs.alert.show("Could not complete “" .. command.title .. "”") end
    end
    local task = hs.task.new(executable, finish, arguments)
    if not task or not task:start() then finish(1) end
end

return actions
