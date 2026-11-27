local home = os.getenv("HOME")
local caffeine = require("modules.glass_launcher.features.launcher-caffeine")
local systemActions = require("modules.glass_launcher.features.launcher-system-actions")
local fileSearchScope = require("modules.glass_launcher.features.launcher-search-scope")
local systemSettings = require("modules.glass_launcher.features.launcher-system-settings")
local paths = require("modules.glass_launcher.core.paths")
local appFolders = fileSearchScope.appFolders
local helper = paths.helper
local resultLimit = 5
local active, debounce, searchTask, dictionaryTask, cancelContentSearch
local translationTasks = {}
local calculator = require("modules.glass_launcher.features.launcher-calculator")
local colors = require("modules.glass_launcher.features.launcher-colors")
local clipboard = require("modules.glass_launcher.features.launcher-clipboard")
local exchangeRates = {}

local function choiceFor(path, isApp)
    local name = path:match("[^/]+$")
    if isApp then name = name:gsub("%.app$", "") end
    return { title = name, subtitle = path, path = path }
end

local function scanApps()
    local apps = {}
    local finder = "/System/Library/CoreServices/Finder.app"
    if hs.fs.attributes(finder, "mode") == "directory" then
        apps[#apps + 1] = choiceFor(finder, true)
    end
    for _, folder in ipairs(appFolders) do
        if hs.fs.attributes(folder, "mode") == "directory" then
            for name in hs.fs.dir(folder) do
                local path = folder .. "/" .. name
                if name:match("%.app$") then
                    local app = choiceFor(path, true)
                    apps[#apps + 1] = app
                end
            end
        end
    end
    table.sort(apps, function(a, b) return a.title:lower() < b.title:lower() end)
    return apps
end

local function cancelSearch()
    if debounce then debounce:stop(); debounce = nil end
    if cancelContentSearch then cancelContentSearch(); cancelContentSearch = nil end
    if searchTask then searchTask:terminate(); searchTask = nil end
    if dictionaryTask then dictionaryTask:terminate(); dictionaryTask = nil end
    for key, task in pairs(translationTasks) do
        translationTasks[key] = nil
        task:terminate()
    end
end

local appearanceKey = "glassLauncherPublicLightMode"
-- Appearance preference: nil = follow system, true = force light, false = force dark.
local function systemLight()
    -- Read the real value via a subprocess: hs.host.interfaceStyle() reads the
    -- in-process NSUserDefaults cache, which can stay stale in a background app.
    local out = hs.execute("defaults read -g AppleInterfaceStyle 2>/dev/null")
    return not (out or ""):find("Dark")
end

local function resolveLightMode()
    local pref = hs.settings.get(appearanceKey)
    if pref == nil then return systemLight() end
    return pref == true
end

local lightMode = resolveLightMode()

local queryHistoryLimit = 20
local queryHistory = {}

local function webAddress(query)
    if query:find("[%s%c\\]") then return end
    local scheme, rest = query:match("^([%a][%w+.-]*)://(.+)$")
    if scheme and scheme:lower() ~= "http" and scheme:lower() ~= "https" then return end
    local authority = (rest or query):match("^[^/?#]+")
    if not authority then return end
    local host = authority:match("^([^:]+):%d+$") or authority
    if not host:match("^[%w.-]+$") and not (scheme and authority:match("^%[[%x:]+%]:?%d*$")) then return end
    if not scheme and not host:match("^[%w][%w.-]*%.[%a][%a]+$") then return end
    return scheme and (scheme:lower() .. "://" .. rest) or ("https://" .. query), scheme ~= nil
end

local function rememberQuery(session)
    local query = session.root.query:match("^%s*(.-)%s*$")
    if query == "" or #query > 512 then return end
    for index, previous in ipairs(queryHistory) do
        if previous.query == query then table.remove(queryHistory, index); break end
    end
    table.insert(queryHistory, 1, { query = query, timestamp = os.time() })
    if #queryHistory > queryHistoryLimit then table.remove(queryHistory) end
end

local function searchIcon()
    return "magnifyingglass"
end

local function sendRows(session, choices, placeholder, resetQuery, context, clipboardMode, navigationPrefix, navigationMessage)
    local rows = {}
    local nextID = 0
    session.choices = {}
    for index, choice in ipairs(choices) do
        local id = choice.resultID
        if not id then
            nextID = nextID + 1
            id = nextID
        end
        session.choices[id] = choice
        rows[index] = {
            id = id, title = choice.title or choice.text,
            subtitle = choice.subtitle or choice.statusText or choice.subText or "",
            storageUsed = choice.storageUsed,
            path = choice.path, appIconPath = choice.launchAppPath, hasAlternate = choice.alternateURL ~= nil, status = choice.statusKind, swatch = choice.swatch,
            canShuffle = choice.shuffle ~= nil, artworkKey = choice.artworkKey, previewText = choice.previewText, previewImage = choice.previewImage, isDirectory = choice.isDirectory,
            icon = choice.icon, symbol = choice.symbol, symbolTile = choice.symbolTile, valid = choice.valid,
        }
    end
    local visibleHistory
    if session.view == session.root and #queryHistory > 0 then
        visibleHistory = {}
        for _, entry in ipairs(queryHistory) do
            if not webAddress(entry.query) then
                visibleHistory[#visibleHistory + 1] = entry
            end
        end
        if #visibleHistory == 0 then visibleHistory = nil end
    end
    local panelCommand = session.panelCommand
    session.panelCommand = nil
    session.task:setInput(hs.json.encode({
        panelCommand = panelCommand,
        request = session.request, lightMode = lightMode, searchIcon = searchIcon(), results = #rows > 0 and rows or nil,
        placeholder = placeholder, resetQuery = resetQuery, context = context, clipboardMode = clipboardMode,
        navigationPrefix = navigationPrefix, navigationMessage = navigationMessage,
        history = visibleHistory, startupInput = session.initialInput,
    }) .. "\n")
end

local function renderView(view, reset)
    local term = view.query:lower():match("^%s*(.-)%s*$")
    local choices, words = {}, {}
    if view.matches then
        for word in term:gmatch("%S+") do words[#words + 1] = word end
    end
    for _, row in ipairs(view.rows) do
        local text = (row.title or row.text):lower()
        if view.matches then
            local keyword = row.searchKeyword
            if keyword and keyword == term then
                table.insert(choices, 1, row)
            elseif view.matches(keyword and (text .. " " .. keyword) or text, words) then
                choices[#choices + 1] = row
            end
        else
            local detail = (row.subText or row.subtitle or ""):lower()
            if text:find(term, 1, true) or detail:find(term, 1, true) then
                choices[#choices + 1] = row
            end
        end
    end
    local emptyMessage = view.clipboardMode and #view.rows == 0 and "Clipboard history is empty" or nil
    sendRows(view.session, choices, view.title, reset and view.query or nil, view.context, view.clipboardMode, nil, emptyMessage)
end

local View = {}
View.__index = View

function View:isCurrent()
    local session = self.session
    return active == session and not session.closing and session.view == self
end

function View:update(rows)
    self.rows = rows
    if self:isCurrent() then renderView(self) end
end

function View:push(title, query, select, enter, leave, options)
    if not self:isCurrent() then return end
    local session = self.session
    cancelSearch()
    if self.leave then self.leave() end
    local child = setmetatable({
        session = session, parent = self, title = title, query = query,
        select = select, enter = enter, leave = leave, rows = {},
    }, View)
    if options then
        child.matches, child.context, child.rows = options.matches, options.context, options.rows or child.rows
        child.clipboardMode = options.clipboardMode
    end
    session.view = child
    renderView(child, true)
    if enter then enter(child) end
end

function View:finish(action)
    if not self:isCurrent() then return end
    local session = self.session
    session.closing, session.afterClose = true, action
    cancelSearch()
    if self.leave then self.leave() end
    session.view = nil
    if session.resident then
        session.task:setInput(hs.json.encode({ request = session.request, panelCommand = "hide" }) .. "\n")
    else
        session.task:closeInput()
    end
end

local function percentEncode(text, allowSlash)
    local pattern = allowSlash and "[^%w%-%._~/]" or "[^%w%-%._~]"
    return (text:gsub(pattern, function(char)
        return string.format("%%%02X", char:byte())
    end))
end

local webSearches = require("modules.glass_launcher.config.launcher-web-searches")
local fallbackIDOffset = 100 -- The dictionary uses result ID -100.
local webSearchByKeyword = {}
for _, provider in ipairs(webSearches) do
    webSearchByKeyword[provider.keyword:lower()] = provider
end

local function webSearchChoice(provider, query, encoded)
    local icon = provider.icon and paths.assets .. "/" .. provider.icon
    local symbol = not icon and "globe" or nil
    if query == "" then
        return {
            title = "Search " .. provider.name,
            subtitle = "Type a search term after " .. provider.keyword,
            icon = icon, symbol = symbol, valid = false,
        }
    end
    return {
        title = "Search " .. provider.name .. " for ‘" .. query .. "’",
        icon = icon, symbol = symbol,
        url = (provider.url:gsub("{query}", function() return encoded end)),
    }
end

local function fallbackChoices(query)
    local choices = {}
    local encoded = percentEncode(query)
    for _, provider in ipairs(webSearches) do
        if provider.fallback then
            local choice = webSearchChoice(provider, query, encoded)
            choice.resultID = -(fallbackIDOffset + #choices + 1)
            choices[#choices + 1] = choice
        end
    end
    return choices
end

local dictionaryAppPath = "/System/Applications/Dictionary.app"

local function lookupDefinition(term, isCurrent, callback)
    local task
    task = hs.task.new(paths.dictionary, function(code, output)
        if dictionaryTask ~= task or not isCurrent() then return end
        dictionaryTask = nil
        local definition = code == 0 and output:match("^%s*(.-)%s*$")
        callback(definition and definition ~= "" and definition or nil)
    end, { term })
    if task and task:start() then
        dictionaryTask = task
    else
        callback(nil)
    end
end

local function definitionChoice(term, definition)
    return {
        title = term, subtitle = definition, launchAppPath = dictionaryAppPath,
        action = "dictionary", term = term, resultID = -100,
    }
end

local translationTargets = {
    { code = "zh-CN", label = "简体中文" },
    { code = "en", label = "English" },
}

local function readTranslation(output)
    local ok, body = pcall(hs.json.decode, output)
    local segments = ok and type(body) == "table" and body[1]
    if type(segments) ~= "table" then return end
    local text = {}
    for _, segment in ipairs(segments) do
        if type(segment) == "table" and type(segment[1]) == "string" then
            text[#text + 1] = segment[1]
        end
    end
    local result = table.concat(text)
    if result:find("%S") then return result end
end

local function translate(text, isCurrent, render)
    local rows = {}
    for index, target in ipairs(translationTargets) do
        rows[index] = {
            title = "Translating…", subtitle = target.label, symbol = "translate", valid = false,
        }
    end
    if #text > 3000 then
        for _, row in ipairs(rows) do row.title = "Text is too long to translate" end
        render(rows)
        return
    end
    render(rows)
    debounce = hs.timer.doAfter(0.35, function()
        debounce = nil
        if not isCurrent() then return end
        for index, target in ipairs(translationTargets) do
            local function update(result)
                local row = rows[index]
                row.title = result or "Translation unavailable"
                row.copyValue, row.valid = result, result ~= nil
                render(rows)
            end
            local task
            task = hs.task.new("/usr/bin/curl", function(code, output)
                if translationTasks[target.code] ~= task or not isCurrent() then return end
                translationTasks[target.code] = nil
                update(code == 0 and readTranslation(output) or nil)
            end, {
                "-fsS", "--max-time", "8", "--get",
                "https://translate.googleapis.com/translate_a/single",
                "--data", "client=gtx&sl=auto&dt=t&tl=" .. target.code,
                "--data-urlencode", "q@-",
            })
            if task then task:setInput(text) end
            if task and task:start() then
                translationTasks[target.code] = task
            else
                update(nil)
            end
        end
    end)
end

local function browserPath(path)
    if path == home then return "~" end
    if path:sub(1, #home + 1) == home .. "/" then return "~" .. path:sub(#home + 1) end
    return path
end

local function browse(session, query, reset)
    local path = query == "~" and (home .. "/") or query
    if path:sub(1, 1) == "~" then
        local suffix = path:sub(2)
        path = home .. (suffix:sub(1, 1) == "/" and "" or "/") .. suffix
    end
    local component = path:match("[^/]+$")
    if component and component ~= "." and component ~= ".."
        and hs.fs.attributes(path, "mode") == "directory"
        and not path:lower():match("%.app$") then
        path, reset = path .. "/", true
    end
    local directory, filter = path:match("^(.*)/([^/]*)$")
    if not directory then return end
    directory = directory:gsub("/+$", "")
    if directory == "" then directory = "/" end
    local prefix = (directory == "/" and "" or browserPath(directory)) .. "/"
    if session.browserDirectory ~= directory then
        local rows = {}
        local ok = pcall(function()
            local stem = directory == "/" and "" or directory
            for name in hs.fs.dir(directory) do
                if name ~= "." and name ~= ".." then
                    local item = stem .. "/" .. name
                    local folder = hs.fs.attributes(item, "mode") == "directory" and not name:lower():match("%.app$")
                    rows[#rows + 1] = { title = name, path = item, isDirectory = not not folder }
                end
            end
        end)
        table.sort(rows, function(a, b)
            if a.isDirectory ~= b.isDirectory then return a.isDirectory end
            local left, right = a.title:lower(), b.title:lower()
            if left == right then return a.title < b.title end
            return left < right
        end)
        session.browserDirectory, session.browserRows, session.browserReadable = directory, rows, ok
    end
    local rows = {}
    local wildcard = filter:sub(1, 1) == "*"
    local needle = filter:lower():gsub("^%*", "")
    local showHidden = needle:sub(1, 1) == "."
    for _, row in ipairs(session.browserRows) do
        local position = row.title:lower():find(needle, 1, true)
        if (showHidden or row.title:sub(1, 1) ~= ".") and (position == 1 or (wildcard and position)) then
            if row.title == filter then
                table.insert(rows, 1, row)
            else
                rows[#rows + 1] = row
            end
        end
    end
    local displayed = reset and (prefix .. filter) or nil
    if displayed then session.root.query = displayed end
    local inputPrefix = displayed and prefix or query:match("^.*/") or prefix
    local message = not session.browserReadable and "Folder unavailable" or nil
    sendRows(session, rows, "Browse files and folders", displayed, nil, nil, inputPrefix, message)
end

local function storageSize(bytes)
    local amount = bytes
    for _, unit in ipairs({ "B", "KB", "MB", "GB", "TB" }) do
        if amount < 1000 or unit == "TB" then return ("%.2f %s"):format(amount, unit) end
        amount = amount / 1000
    end
end

local function search(session, request, query, reset)
    cancelSearch()
    session.request = request
    session.root.query = query
    session.fallbackChoices = nil
    session.dictionaryChoice = nil
    local term = query:match("^%s*(.-)%s*$")
    local lower = term:lower()
    local systemAction = systemActions.result(lower)
    if systemAction then
        session.browserDirectory, session.browserRows = nil, nil
        sendRows(session, { systemAction }, session.root.title,
            reset and query or nil)
        return
    end
    local eject = lower == "eject"
    if eject or lower == "storage" or lower == "存储空间" then
        session.browserDirectory, session.browserRows = nil, nil
        local storageSettings = not eject and systemSettings.results("storage", 1)[1] or nil
        local function render(rows)
            rows[#rows + 1] = storageSettings
            sendRows(session, rows, session.root.title, reset and query or nil)
            reset = false
        end
        local unavailable = {{ title = "Storage information unavailable", symbol = "internaldrive", valid = false }}
        render({{ title = "Reading storage…", symbol = "internaldrive", valid = false }})
        local task
        task = hs.task.new(helper, function(code, output)
            if searchTask ~= task or active ~= session or session.request ~= request then return end
            searchTask = nil
            local ok, volumes = pcall(hs.json.decode, code == 0 and output or "[]")
            if not ok or type(volumes) ~= "table" or #volumes == 0 then render(unavailable); return end
            local rows = {}
            for _, volume in ipairs(volumes) do
                if eject then
                    if volume.external and type(volume.mountPath) == "string" and volume.mountPath:sub(1, 1) == "/" then
                        rows[#rows + 1] = {
                            title = "Eject " .. volume.name,
                            subtitle = volume.mountPath,
                            symbol = "eject",
                            action = "ejectVolume",
                            mountPath = volume.mountPath,
                            volumeName = volume.name,
                        }
                    end
                else
                    rows[#rows + 1] = {
                        title = volume.name,
                        subtitle = ("%s of %s used · %s free"):format(
                            storageSize(volume.used), storageSize(volume.total), storageSize(volume.total - volume.used)),
                        symbol = volume.external and "externaldrive" or "internaldrive",
                        storageUsed = volume.used / volume.total,
                        valid = false,
                    }
                end
            end
            if eject and #rows == 0 then
                rows[1] = { title = "No external disks to eject", symbol = "eject", valid = false }
            end
            render(rows)
        end, { "--storage-volumes" })
        if task and task:start() then searchTask = task else render(unavailable) end
        return
    end
    if lower == ".caffeine" or lower == "keep awake" or lower == "咖啡因"
        or (#lower >= 3 and ("caffeine"):sub(1, #lower) == lower) then
        session.browserDirectory, session.browserRows = nil, nil
        local enabled = caffeine.enabled()
        sendRows(session, {{
            title = enabled and "Turn Caffeine Off" or "Turn Caffeine On",
            subtitle = enabled and "Keep Awake is on" or "Prevent idle sleep and the screen saver",
            statusKind = enabled and "caffeineOn" or "caffeineOff",
            action = "toggleCaffeine",
        }}, session.root.title, reset and query or nil)
        return
    end
    local reloadTitle = "Reload Hammerspoon Configuration"
    if lower == ".reload" or lower == "reload config"
        or (#lower >= 3 and reloadTitle:lower():sub(1, #lower) == lower) then
        session.browserDirectory, session.browserRows = nil, nil
        sendRows(session, {{
            title = reloadTitle,
            symbol = "arrow.clockwise", action = "reloadHammerspoon",
        }}, session.root.title, reset and query or nil)
        return
    end
    if query:sub(1, 1) == "~" or query:sub(1, 1) == "/" then
        browse(session, query, reset or query == "~")
        return
    end
    if query:find("/", 1, true) and not query:find("://", 1, true)
        and hs.fs.attributes(home .. "/" .. query, "mode") then
        browse(session, "~/" .. query, true)
        return
    end
    session.browserDirectory, session.browserRows = nil, nil
    local placeholder = session.root.title
    query = query:match("^%s*(.-)%s*$")
    if query == "" then
        sendRows(session, {}, placeholder, reset and session.root.query or nil)
        return
    end

    local function isCurrent()
        return active == session and session.request == request and not session.closing and session.view == session.root
    end

    local address, explicitAddress = webAddress(query)
    local addressChoice = address and { title = "Open Website", subtitle = address, symbol = "globe", url = address }
    if explicitAddress then
        sendRows(session, { addressChoice }, placeholder, reset and session.root.query or nil)
        return
    end

    local lowerQuery = query:lower()
    local settingsQuery = lowerQuery:match("^settings%s+(.+)$")
        or lowerQuery:match("^system settings%s+(.+)$") or query:match("^系统设置%s+(.+)$")
    if settingsQuery or lowerQuery == "settings" or query == "系统设置" then
        local rows = systemSettings.results(settingsQuery or "")
        if #rows == 0 then rows[1] = { title = "No matching settings", valid = false } end
        sendRows(session, rows, "Search System Settings", reset and session.root.query or nil)
        return
    end

    if lowerQuery == "theme" or lowerQuery == ".theme" then
        local pref = hs.settings.get(appearanceKey)
        local mode = pref == nil and "auto" or (pref and "light" or "dark")
        local function themeRow(value, title, subtitle, symbol)
            return {
                title = (mode == value and "✓ " or "") .. title,
                subtitle = subtitle, symbol = symbol,
                action = "toggleAppearance", appearance = value,
            }
        end
        sendRows(session, {
            themeRow("auto", "Follow System", "System is currently in " .. (systemLight() and "Light" or "Dark") .. " Mode", "circle.lefthalf.filled"),
            themeRow("light", "Light Mode", "Always use Light Mode", "sun.max"),
            themeRow("dark", "Dark Mode", "Always use Dark Mode", "moon"),
        }, placeholder, reset and session.root.query or nil)
        return
    end

    local contentTerm = query:match("^[Gg][Rr][Ee][Pp]%s+(.+)$")
    if query:lower() == "grep" or contentTerm then
        local function render(choices)
            sendRows(session, choices, placeholder, reset and session.root.query or nil)
            reset = false
        end
        local function status(title)
            render({ { title = title, symbol = "doc.text.magnifyingglass", valid = false } })
        end
        if not contentTerm then
            status("Type text after grep to search documents")
            return
        end
        status("Searching document contents…")
        debounce = hs.timer.doAfter(0.25, function()
            debounce = nil
            if not isCurrent() then return end
            cancelContentSearch = require("modules.glass_launcher.features.launcher-content-search").start(contentTerm, function(matches, done, timedOut)
                if not isCurrent() then return end
                if #matches == 0 then
                    if done then status(timedOut and "Search timed out" or "No matching documents") end
                    return
                end
                local choices = {}
                for _, match in ipairs(matches) do
                    local choice = choiceFor(match.path, false)
                    choice.subtitle = match.kind .. " · " .. choice.subtitle
                    choices[#choices + 1] = choice
                end
                render(choices)
            end)
        end)
        return
    end

    local translationText = query:match("^[Tt][Ll]%s+(.+)$")
    if translationText then
        translate(translationText, isCurrent, function(rows)
            sendRows(session, rows, placeholder, reset and session.root.query or nil)
            reset = false
        end)
        return
    end

    local dictionaryTerm = query:match("^[Dd][Ee][Ff][Ii][Nn][Ee]%s+(.+)$")
        or query:match("^[Dd][Ii][Cc][Tt]%s+(.+)$")
    if dictionaryTerm and #dictionaryTerm <= 200 then
        sendRows(session, {{
            title = "Looking up ‘" .. dictionaryTerm .. "’…", launchAppPath = dictionaryAppPath, valid = false,
        }}, placeholder, reset and session.root.query or nil)
        lookupDefinition(dictionaryTerm, isCurrent, function(definition)
            session.dictionaryChoice = definitionChoice(dictionaryTerm, definition or "Open in Dictionary")
            sendRows(session, { session.dictionaryChoice }, placeholder)
        end)
        return
    end

    if query:lower() == "clear" or query:lower() == "clear clipboard history" then
        local choices = {}
        for _, minutes in ipairs({ 5, 15, 30 }) do
            choices[#choices + 1] = {
                title = string.format("Clear Clipboard History · Last %d Minutes", minutes),
                subtitle = "Remove recent items from GlassLauncher",
                symbol = "list.clipboard", action = "clearClipboardHistory", minutes = minutes,
            }
        end
        choices[#choices + 1] = {
            title = "Clear All Clipboard History", subtitle = "Remove all items from GlassLauncher",
            symbol = "list.clipboard", action = "clearClipboardHistory",
        }
        sendRows(session, choices, placeholder, reset and session.root.query or nil)
        return
    end

    local colorChoices = colors.choices(query)
    if colorChoices then
        sendRows(session, colorChoices, placeholder, reset and session.root.query or nil)
        return
    end

    local function showCalculation(title, subtitle, value)
        sendRows(session, {{
            title = title, subtitle = subtitle, symbol = "calculator",
            copyValue = value, valid = value ~= nil,
        }}, placeholder, reset and session.root.query or nil)
        reset = false
    end

    local calculated = calculator.evaluate(query)
    if calculated ~= nil then
        local display, value = calculator.format(calculated)
        showCalculation(display, query .. " =", value)
        return
    end

    local amount, base, quote = calculator.currency(query)
    if amount then
        local function showRate(rate, date)
            local converted = amount * rate
            if converted ~= converted or math.abs(converted) == math.huge then
                showCalculation("Conversion is out of range", query)
                return
            end
            local display, value = calculator.format(converted, 2)
            local detail = query .. " ="
            if date then detail = detail .. "  ·  Frankfurter  ·  " .. date end
            showCalculation(display .. " " .. quote, detail, value .. " " .. quote)
        end
        if base == quote then
            showRate(1)
            return
        end
        local pair = base .. quote
        local cached = exchangeRates[pair]
        if cached and os.time() - cached.fetched < 900 then
            showRate(cached.rate, cached.date)
            return
        end
        showCalculation("Fetching exchange rate…", query)
        debounce = hs.timer.doAfter(0.15, function()
            debounce = nil
            if not isCurrent() then return end
            local url = "https://api.frankfurter.dev/v2/rates?base=" .. base .. "&quotes=" .. quote
            local task
            task = hs.task.new("/usr/bin/curl", function(code, output)
                if searchTask ~= task or not isCurrent() then return end
                searchTask = nil
                local ok, rows = pcall(hs.json.decode, output)
                local row = ok and type(rows) == "table" and rows[1]
                if code ~= 0 or type(row) ~= "table" or row.base ~= base or row.quote ~= quote
                    or type(row.rate) ~= "number" or row.rate <= 0 or row.rate >= math.huge
                    or type(row.date) ~= "string" then
                    showCalculation("Exchange rate unavailable", query)
                    return
                end
                exchangeRates[pair] = { rate = row.rate, date = row.date, fetched = os.time() }
                showRate(row.rate, row.date)
            end, { "-fsS", "--max-time", "5", url })
            if task and task:start() then
                searchTask = task
            else
                showCalculation("Exchange rate unavailable", query)
            end
        end)
        return
    end

    local keyword, webQuery = query:match("^(%S+)%s*(.*)$")
    local provider = webSearchByKeyword[keyword:lower()]
    if provider then
        local choice = webSearchChoice(provider, webQuery, percentEncode(webQuery))
        sendRows(session, { choice }, placeholder, reset and session.root.query or nil)
        return
    end

    local term = query:lower()
    session.apps = session.apps or scanApps()
    local apps, files = {}, {}
    local settingsRows = systemSettings.results(query, 3)
    local appLimit = resultLimit - #settingsRows
    local matches = {}
    for _, app in ipairs(session.apps) do
        local name = app.title:lower()
        local position = name:find(term, 1, true)
        if position then
            matches[#matches + 1] = { app = app, name = name, position = position }
        end
    end
    table.sort(matches, function(a, b)
        if a.position ~= b.position then return a.position < b.position end
        if #a.name ~= #b.name then return #a.name < #b.name end
        if a.name ~= b.name then return a.name < b.name end
        return a.app.path < b.app.path
    end)
    for index = 1, math.min(#matches, appLimit) do
        apps[#apps + 1] = matches[index].app
    end

    local function renderMatches()
        local choices = {}
        if apps[1] and apps[1].title:lower() == term then choices[#choices + 1] = apps[1] end
        for _, choice in ipairs(settingsRows) do choices[#choices + 1] = choice end
        for _, choice in ipairs(apps) do
            if choice.title:lower() ~= term or choice ~= apps[1] then choices[#choices + 1] = choice end
        end
        for _, choice in ipairs(files) do choices[#choices + 1] = choice end
        if addressChoice then
            local exactFile
            for _, choice in ipairs(choices) do
                if choice.path and choice.path:match("[^/]+$"):lower() == term then
                    exactFile = true
                    break
                end
            end
            if exactFile then
                choices[#choices + 1] = addressChoice
            else
                table.insert(choices, 1, addressChoice)
            end
        end
        if #choices == 0 then
            session.fallbackChoices = session.fallbackChoices or fallbackChoices(query)
            for _, choice in ipairs(session.fallbackChoices) do choices[#choices + 1] = choice end
        end
        if session.dictionaryChoice then
            local afterApp = term == "dictionary" and apps[1] and apps[1].title:lower() == term
            table.insert(choices, afterApp and 2 or 1, session.dictionaryChoice)
        end
        sendRows(session, choices, placeholder, reset and session.root.query or nil)
        reset = false
    end

    local fileLimit = appLimit - #apps
    local searchFiles = #query >= 2 and fileLimit > 0
    renderMatches()
    local searchDictionary = term == "dictionary" or (
        searchFiles and #apps == 0 and #settingsRows == 0
        and #query >= 3 and #query <= 48 and query:match("^%a[%a'%-]*$"))
    if not searchFiles and not searchDictionary then return end

    debounce = hs.timer.doAfter(0.03, function()
        debounce = nil
        if not isCurrent() then return end
        if searchDictionary then
            lookupDefinition(query, isCurrent, function(definition)
                if definition then
                    session.dictionaryChoice = definitionChoice(query, definition)
                    renderMatches()
                end
            end)
        end
        if not searchFiles then return end
        local escaped = query:gsub('([\\"*?])', '\\%1')
        local seen = {}
        for _, app in ipairs(session.apps) do seen[app.path] = true end

        local pathTerms = {}
        for word in term:gmatch("%S+") do pathTerms[#pathTerms + 1] = word end

        local function matchesPath(path)
            if #pathTerms < 2 then return true end
            local lower = path:lower()
            for _, word in ipairs(pathTerms) do
                if not lower:find(word, 1, true) then return false end
            end
            return true
        end

        local function findFiles(pattern, onComplete)
            local predicate = pattern and ('kMDItemFSName == "' .. pattern .. '"cd')
            local args = fileSearchScope.spotlightArguments(predicate, true)
            if not args then return end
            local task
            local remainder = ""
            local function collect(output)
                local data = remainder .. (output or "")
                local offset = 1
                while #files < fileLimit do
                    local stop = data:find("%z", offset)
                    if not stop then break end
                    local path = data:sub(offset, stop - 1)
                    offset = stop + 1
                    if path ~= "" and not seen[path] and fileSearchScope.searchablePath(path) and matchesPath(path) then
                        seen[path] = true
                        files[#files + 1] = choiceFor(path, path:match("%.app$"))
                    end
                end
                remainder = #files < fileLimit and data:sub(offset) or ""
            end
            task = hs.task.new("/usr/bin/mdfind", function(code, output)
                if searchTask ~= task or not isCurrent() then return end
                searchTask = nil
                if code == 0 then collect(output) end
                if #files > 0 then renderMatches() end
                if #files < fileLimit and onComplete then onComplete() end
            end, function(_, output)
                if searchTask ~= task or not isCurrent() then return false end
                local count = #files
                collect(output)
                if #files > count then renderMatches() end
                if #files == fileLimit then
                    searchTask = nil
                    task:terminate()
                    return false
                end
                return true
            end, args)
            if task and task:start() then
                searchTask = task
            elseif onComplete then
                onComplete()
            end
        end

        if #pathTerms > 1 then
            for _, path in ipairs(fileSearchScope.matchPaths(pathTerms, function(path)
                return not seen[path] and fileSearchScope.searchablePath(path)
            end, fileLimit)) do
                seen[path] = true
                files[#files + 1] = choiceFor(path, path:match("%.app$"))
            end
            if #files > 0 then renderMatches() end
            if #files < fileLimit then findFiles(nil) end
        else
            findFiles(escaped .. '*', function()
                findFiles('*' .. escaped .. '*')
            end)
        end
    end)
end

local function openPath(path, reveal)
    hs.task.new("/usr/bin/open", nil, reveal and { "-R", path } or { path }):start()
end

local universalActions = require("modules.glass_launcher.actions.universal-actions")

local function pushUniversalActions(parent, kind, subject)
    local rows = universalActions.rows(kind, subject)
    if #rows == 0 then
        rows = {{ title = "No actions registered", valid = false }}
    end
    parent:push("Filter actions", "", function(view, choice)
        view:finish(choice.run)
    end, nil, nil, {
        context = { title = subject.title, path = subject.path },
        rows = rows,
        matches = function(text, words)
            for _, word in ipairs(words) do
                if not text:find(word, 1, true) then return false end
            end
            return true
        end,
    })
end

local function pushFileActions(parent, path)
    pushUniversalActions(parent, "file", { path = path, title = path:match("([^/]+)/?$") or path })
end

local function pushTextActions(parent, text)
    pushUniversalActions(parent, "text", { text = text, title = text })
end

local function pushClipboardActions(parent, choice)
    if choice.previewText then
        pushTextActions(parent, choice.previewText)
    elseif choice.previewImage then
        pushUniversalActions(parent, "image", { path = choice.previewImage, title = choice.title or choice.text })
    end
end

function View:back()
    if not self:isCurrent() then return end
    local parent = self.parent
    if self.clipboardMode or not parent then self:finish(); return end
    if self.leave then self.leave() end
    local session = self.session
    session.view = parent
    if parent == session.root then
        search(session, session.request, parent.query, true)
    else
        renderView(parent, true)
        if parent.enter then parent.enter(parent) end
    end
end

local function refreshAppearance()
    local nextMode = resolveLightMode()
    if nextMode == lightMode then return end
    lightMode = nextMode
    if active and active.view then
        search(active, active.request, active.view.query)
    end
end

local appearanceWatcher = hs.distributednotifications.new(function()
    refreshAppearance()
end, "AppleInterfaceThemeChangedNotification")
appearanceWatcher:start()

-- Fallback: distributed notifications are not guaranteed to be delivered.
-- Poll once a second, but only while the panel is open (zero cost when idle).
local appearancePoll = hs.timer.doEvery(1, function()
    if active then refreshAppearance() end
end)

local startupInput

local function handleEvent(session, line, event)
    if not event then
        local ok, decoded = pcall(hs.json.decode, line)
        if not ok then return end
        event = decoded
    end
    if type(event) ~= "table" or type(event.request) ~= "number" then return end
    if session.resident and event.panelHidden then
        if event.request < session.requestBase then return end
        active = nil
        if startupInput and startupInput.session == session then
            startupInput.timer:stop()
            startupInput = nil
        end
        rememberQuery(session)
        cancelSearch()
        if session.view and session.view.leave then session.view.leave() end
        if session.afterClose then session.afterClose() end
        return
    end
    if session.closing or (session.resident and event.request < session.requestBase) then return end
    if event.startupReady and startupInput and startupInput.session == session then
        local text = table.concat(startupInput.keys)
        startupInput.timer:stop()
        startupInput = nil
        session.initialInput = text
        search(session, session.request, "")
        session.initialInput = nil
        return
    end
    if type(event.previewOpen) == "boolean" then
        session.previewOpen = event.previewOpen
        return
    end
    local view = session.view
    if type(event.query) == "string" and event.request > session.request then
        if view == session.root then
            search(session, event.request, event.query)
        else
            session.request, view.query = event.request, event.query
            renderView(view)
        end
    elseif event.request == session.request and event.browseParent then
        if view == session.root and session.browserDirectory and session.browserDirectory ~= "/" then
            local directory = session.browserDirectory:match("^(.*)/[^/]+$")
            search(session, session.request, directory == "" and "/" or (browserPath(directory) .. "/"), true)
        end
    elseif event.request == session.request and event.back then
        view:back()
    elseif event.request == session.request and type(event.choice) == "number" then
        local choice
        if event.choice == -100 and view == session.root then
            choice = session.dictionaryChoice
        elseif event.choice < 0 then
            -- A web result may have been clicked just before local results replaced it.
            if view == session.root and not event.fileAction and session.fallbackChoices then
                choice = session.fallbackChoices[-event.choice - fallbackIDOffset]
            end
        else
            choice = session.choices[event.choice]
        end
        if not choice or choice.valid == false then return end
        if view == session.root and session.browserDirectory and choice.path and (
            event.fileAction == "completePath" or (choice.isDirectory and
                (not event.fileAction or event.fileAction == "browse" or event.fileAction == "enterFolder"))
        ) then
            local path = browserPath(choice.path) .. (choice.isDirectory and "/" or "")
            search(session, session.request, path, true)
        elseif event.fileAction == "openPath" and choice.path then
            view:finish(function() openPath(choice.path) end)
        elseif event.fileAction == "reveal" and choice.alternateURL then
            view:finish(function() openPath(choice.alternateURL) end)
        elseif event.fileAction == "reveal" and choice.path then
            view:finish(function() openPath(choice.path, true) end)
        elseif event.fileAction == "actions" or event.fileAction == "browse" then
            if view.clipboardMode then
                pushClipboardActions(view, choice)
            elseif choice.path then
                pushFileActions(view, choice.path)
            end
        elseif view ~= session.root then
            if view.select then view.select(view, choice, event) end
            if view:isCurrent() then renderView(view) end
        elseif choice.launchAppPath then
            view:finish(function() openPath(choice.launchAppPath) end)
        elseif choice.action == "ejectVolume" then
            view:finish(function()
                local task = hs.task.new("/usr/sbin/diskutil", function(code)
                    if code == 0 then
                        hs.notify.new({ title = "Disk Ejected", informativeText = choice.volumeName }):send()
                    else
                        hs.alert.show("Could not eject " .. choice.volumeName)
                    end
                end, { "eject", choice.mountPath })
                if not task or not task:start() then hs.alert.show("Could not start disk eject") end
            end)
        elseif choice.action == "systemAction" then
            local command = choice.systemCommand
            local function run() systemActions.run(command) end
            if command.confirm then
                view:push("Confirm system action", "", function(dialog, row)
                    if row.confirm then dialog:finish(run) else dialog:back() end
                end, nil, nil, {
                    context = { title = command.title .. "?" },
                    rows = {
                        { title = "Cancel", symbol = "xmark" },
                        { title = "Confirm " .. command.title, symbol = command.symbol, confirm = true },
                    },
                })
            else
                view:finish(run)
            end
        elseif choice.action == "toggleCaffeine" then
            view:finish(function()
                hs.alert.show(caffeine.toggle() and "Caffeine on" or "Caffeine off")
            end)
        elseif choice.action == "reloadHammerspoon" then
            view:finish(function() hs.timer.doAfter(0, hs.reload) end)
        elseif choice.action == "toggleAppearance" then
            if choice.appearance == "auto" then
                hs.settings.clear(appearanceKey)
            else
                hs.settings.set(appearanceKey, choice.appearance == "light")
            end
            refreshAppearance()
            search(session, session.request, view.query)
        elseif choice.action == "clearClipboardHistory" then
            view:finish(function()
                local removed = clipboard.clear(choice.minutes)
                hs.alert.show(string.format("Clipboard history: %d removed", removed))
            end)
        elseif choice.action == "dictionary" then
            view:finish(function() openPath("dict://" .. percentEncode(choice.term)) end)
        elseif choice.copyValue then
            view:finish(function() hs.pasteboard.setContents(choice.copyValue) end)
        elseif choice.path or choice.url then
            view:finish(function() openPath(choice.path or choice.url) end)
        end
    end
end

local function closeActive()
    if not active then return end
    local session = active
    active = nil
    rememberQuery(session)
    cancelSearch()
    if session.view and session.view.leave then session.view.leave() end
    if session.resident then
        session.task:setInput(hs.json.encode({ request = session.request, panelCommand = "hide" }) .. "\n")
    else
        session.task:terminate()
    end
end

local residentTask
local residentRequestBase = 0

local function ensureResident()
    if residentTask then return residentTask end
    local buffer, task = ""
    local connection, pending = {}, {}
    local nextID, inFlight = 0, nil

    -- hs.task:setInput replaces any bytes it has not sent yet.
    local function sendNext()
        if inFlight or #pending == 0 then return end
        local reply = table.remove(pending, 1)
        inFlight = reply.id
        task:setInput(reply.line)
    end

    function connection:setInput(line)
        nextID = nextID + 1
        local prefix = ('{"deliveryID":%d,'):format(nextID)
        pending[#pending + 1] = { id = nextID, line = prefix .. line:sub(2) }
        sendNext()
    end

    function connection:closeInput()
        task:closeInput()
    end

    task = hs.task.new(helper, function(code, _, stderr)
        if residentTask ~= connection then return end
        residentTask = nil
        local session = active
        if not session or session.task ~= connection then return end
        if startupInput and startupInput.session == session then
            startupInput.timer:stop()
            startupInput = nil
        end
        active = nil
        rememberQuery(session)
        cancelSearch()
        if session.view and session.view.leave then session.view.leave() end
        if session.afterClose then session.afterClose()
        elseif code ~= 0 and stderr ~= "" then print("Main Chooser: " .. stderr) end
    end, function(_, stdout)
        buffer = buffer .. stdout
        while true do
            local newline = buffer:find("\n", 1, true)
            if not newline then break end
            local line = buffer:sub(1, newline - 1)
            buffer = buffer:sub(newline + 1)
            local ok, event = pcall(hs.json.decode, line)
            if ok and type(event) == "table" then
                if event.deliveryID then
                    if event.deliveryID == inFlight then
                        inFlight = nil
                        sendNext()
                    end
                elseif active and active.task == connection then
                    handleEvent(active, nil, event)
                end
            end
        end
        return true
    end, { "--resident" })
    if task and task:start() then
        residentTask = connection
        return connection
    end
end

local previousShutdown = hs.shutdownCallback
hs.shutdownCallback = function()
    if residentTask then residentTask:closeInput() end
    if previousShutdown then previousShutdown() end
end

local function launch(start, arguments, pending, clipboardLaunch)
    lightMode = resolveLightMode()
    if startupInput and startupInput ~= pending then
        startupInput.timer:stop()
        startupInput = nil
    end
    closeActive()
    local session = { buffer = "", request = 0, choices = {} }
    session.root = setmetatable({
        session = session, title = "Search apps, files, and folders", query = "", rows = {},
    }, View)
    session.view = session.root
    local buffered = pending
    if buffered then buffered.session = session end
    if buffered or clipboardLaunch then
        local task = ensureResident()
        if task then
            residentRequestBase = residentRequestBase + 1000000
            session.task, session.resident = task, true
            session.request, session.requestBase = residentRequestBase, residentRequestBase
            active = session
            if start then
                session.panelCommand = "show"
                start(session.root)
                return
            end
            task:setInput(hs.json.encode({
                request = session.request, panelCommand = "show", resetQuery = "",
                lightMode = lightMode, searchIcon = searchIcon(), placeholder = session.root.title,
            }) .. "\n")
            return
        end
    end
    local launchArguments = { table.unpack(arguments or {}) }
    launchArguments[#launchArguments + 1] = "--search-icon=" .. searchIcon()
    if lightMode then launchArguments[#launchArguments + 1] = "--light-appearance" end
    session.task = hs.task.new(helper, function(code, _, stderr)
        if active ~= session then return end
        if startupInput == pending and pending then
            pending.timer:stop()
            startupInput = nil
        end
        active = nil
        rememberQuery(session)
        cancelSearch()
        if session.view and session.view.leave then session.view.leave() end
        if session.afterClose then
            session.afterClose()
        elseif code ~= 0 then
            if stderr ~= "" then print("Main Chooser: " .. stderr) end
            hs.alert.show("主搜索窗口未能打开")
        end
    end, function(_, stdout)
        if active ~= session then return false end
        session.buffer = session.buffer .. stdout
        while true do
            local newline = session.buffer:find("\n", 1, true)
            if not newline then break end
            local line = session.buffer:sub(1, newline - 1)
            session.buffer = session.buffer:sub(newline + 1)
            handleEvent(session, line)
        end
        return true
    end, launchArguments)
    active = session
    if not session.task or not session.task:start() then
        if startupInput == pending and pending then
            pending.timer:stop()
            startupInput = nil
        end
        active = nil
        hs.alert.show("主搜索窗口未能打开")
    elseif start then
        start(session.root)
    elseif not pending then
        search(session, session.request, "")
    end
end

local function cancelStartup()
    local pending = startupInput
    if not pending then return end
    startupInput = nil
    pending.timer:stop()
    if pending.session and active == pending.session then closeActive() end
end

local function beginStartup()
    local pending = { keys = {} }
    startupInput = pending
    pending.timer = hs.timer.doAfter(2, cancelStartup)
    hs.timer.doAfter(0, function()
        if startupInput == pending then launch(nil, { "--buffer-startup" }, pending) end
    end)
end

local function showFileActions(path)
    launch(function(root) pushFileActions(root, path) end)
end

local selectionCopyTask
local function copySelection(app, callback)
    if selectionCopyTask then return end
    local function isFrontmost()
        local front = hs.application.frontmostApplication()
        return front and front:pid() == app:pid()
    end
    local received, sent = "", false
    local resume
    local task = hs.task.new(helper, function(_, output)
        selectionCopyTask = nil
        if resume then resume() end
        if not isFrontmost() then return end
        local payload = (received .. output):match("^ready %d+\n(.*)$")
        local ok, result = pcall(hs.json.decode, payload or "{}")
        callback(ok and type(result) == "table" and result or nil)
    end, function(task, output)
        received = received .. output
        if sent then return true end
        local count = tonumber(received:match("^ready (%d+)\n"))
        if count then
            sent = true
            if not isFrontmost() or hs.pasteboard.changeCount() ~= count then
                task:closeInput()
            else
                resume = clipboard.pauseCapture()
                hs.eventtap.keyStroke({ "cmd" }, "c", 0, app)
                task:setInput("copy\n")
            end
        end
        return true
    end, { "--read-copied-selection" })
    if task and task:start() then selectionCopyTask = task else callback(nil) end
end

local function showSelectionActions()
    local app = hs.application.frontmostApplication()
    if app and app:bundleID() == "com.apple.finder" then
        local ok, url = hs.osascript.applescript([[
            tell application "Finder"
                set chosenItems to get selection as list
                if chosenItems is {} then return ""
                return URL of item 1 of chosenItems
            end tell
        ]])
        local encodedPath = ok and type(url) == "string" and url:match("^file://(/.+)$")
        if encodedPath then
            local path = encodedPath:gsub("%%(%x%x)", function(hex)
                return string.char(tonumber(hex, 16))
            end)
            showFileActions(path)
            return
        end
    end
    local element = app and hs.axuielement.applicationElement(app):attributeValue("AXFocusedUIElement")
    local text = element and element:attributeValue("AXSelectedText")
    local function show(selected)
        if type(selected) ~= "string" or not selected:find("%S") then
            hs.alert.show("Select text or a Finder item first")
            return
        end
        launch(function(root) pushTextActions(root, selected) end)
    end
    if (type(text) ~= "string" or not text:find("%S")) and app then
        copySelection(app, function(selection)
            if selection and type(selection.path) == "string" and selection.path ~= "" then
                showFileActions(selection.path)
            else
                show(selection and selection.text)
            end
        end)
    else
        show(text)
    end
end

local hotkeys = require("modules.glass_launcher.config.hotkeys")
for _, name in ipairs({ "launcher", "selection", "clipboard" }) do
    assert(#hotkeys[name].mods > 0, "Glass Launcher: " .. name .. " needs a modifier in config/hotkeys.lua")
end
local launcherKey = assert(hs.keycodes.map[hotkeys.launcher.key],
    "Glass Launcher: invalid launcher key in config/hotkeys.lua")
local clipboardHotkey = hs.hotkey.bind(hotkeys.clipboard.mods, hotkeys.clipboard.key, function()
    local target = active and active.clipboardTarget or hs.application.frontmostApplication()
    launch(function(root)
        root.session.clipboardTarget = target
        local title = "Search clipboard history"
        root:push(title, "", function(view, choice, event)
            view:finish(function()
                if event.copyOnly == true then
                    clipboard.copy(choice)
                else
                    clipboard.paste(choice, target)
                end
            end)
        end, nil, nil, { clipboardMode = true, rows = clipboard.rows() })
    end, { "--clipboard" }, nil, true)
end)

local textActionHotkey = hs.hotkey.bind(hotkeys.selection.mods, hotkeys.selection.key, showSelectionActions)

local events = hs.eventtap.event
local launcherHotkey = hs.eventtap.new({ events.types.keyDown }, function(event)
    local key = event:getKeyCode()
    if active and active.previewOpen and key == hs.keycodes.map.escape
        and event:getFlags():containExactly({}) then
        if event:getProperty(events.properties.keyboardEventAutorepeat) == 0 then
            active.task:setInput(hs.json.encode({ request = active.request, closePreview = true }) .. "\n")
        end
        return true
    end
    local flags = event:getFlags()
    local repeated = event:getProperty(events.properties.keyboardEventAutorepeat) ~= 0
    if key == launcherKey and flags:containExactly(hotkeys.launcher.mods) then
        if event:getProperty(events.properties.keyboardEventAutorepeat) == 0 then
            if startupInput then
                hs.timer.doAfter(0, cancelStartup)
            elseif active then
                hs.timer.doAfter(0, closeActive)
            else
                beginStartup()
            end
        end
        return true
    end
    if not startupInput or flags.cmd or flags.ctrl then return false end
    if key == hs.keycodes.map.escape then
        hs.timer.doAfter(0, cancelStartup)
        return true
    end
    local keys = startupInput.keys
    if key == hs.keycodes.map.delete then
        local last = keys[#keys]
        if last then
            local offset = utf8.offset(last, -1)
            keys[#keys] = offset and offset > 1 and last:sub(1, offset - 1) or nil
        end
        return true
    end
    if flags.fn then return false end
    local text = event:getCharacters()
    if type(text) == "string" and text ~= "" and not text:find("%c") then
        if #keys < 512 then keys[#keys + 1] = text end
        return true
    end
    return false
end):start()

local function prewarm()
    ensureResident()
    hs.timer.doAfter(0.15, fileSearchScope.warmPathIndex)
end

return { prewarm = prewarm, launcherHotkey = launcherHotkey, showFileActions = showFileActions, textActionHotkey = textActionHotkey, clipboardHotkey = clipboardHotkey,
    -- Keep watcher/timer reachable so Lua GC never collects them.
    appearanceWatcher = appearanceWatcher, appearancePoll = appearancePoll }
