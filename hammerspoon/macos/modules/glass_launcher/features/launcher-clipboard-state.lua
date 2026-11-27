local state = {}
local legacyKey = "glassLauncherPublicClipboardReloadState"
local pid = hs.application.get(hs.processInfo.bundleID):pid()
local directory = os.getenv("HOME") .. "/Library/Application Support/GlassLauncher Public Clipboard History"
local historyPath = directory .. "/history.json"
local pendingDeletes = {}

local function privateDirectory()
    local mode = hs.fs.symlinkAttributes(directory, "mode")
    if mode then
        return mode == "directory"
            and hs.fs.attributes(directory, "permissions") == "rwx------"
    end
    local quoted = "'" .. directory:gsub("'", "'\\''") .. "'"
    return os.execute("/bin/mkdir -m 700 " .. quoted) == true
end

function state.imagePath()
    if not privateDirectory() then return end
    local temp = os.tmpname()
    os.remove(temp)
    return directory .. "/image-" .. temp:match("[^/]+$") .. ".png"
end

function state.removeImage(path)
    pendingDeletes[#pendingDeletes + 1] = path
end

function state.save(entries, observedChangeCount, clearedChangeCount)
    if not privateDirectory() then return false end
    local ok, data = pcall(hs.json.encode, {
        pid = pid, entries = entries,
        observedChangeCount = observedChangeCount,
        clearedChangeCount = clearedChangeCount,
    })
    if not ok or not data then return false end

    local path = historyPath .. ".new"
    local file = io.open(path, "wb")
    if not file then return false end
    local written = file:write(data)
    local closed = file:close()
    if not written or not closed or not os.rename(path, historyPath) then
        os.remove(path)
        return false
    end
    for _, image in ipairs(pendingDeletes) do os.remove(image) end
    pendingDeletes = {}
    return true
end

local function readSnapshot(path)
    local file = io.open(path, "rb")
    if not file then return end
    local data = file:read("*a")
    file:close()
    local ok, snapshot = pcall(hs.json.decode, data)
    if ok and type(snapshot) == "table" and type(snapshot.entries) == "table" then return snapshot end
end

local function migrateLegacy()
    local saved = hs.settings.get(legacyKey)
    if type(saved) ~= "table" or type(saved.path) ~= "string" then return end
    local snapshot = readSnapshot(saved.path)
    if not snapshot then return end
    snapshot.pid = saved.pid
    local oldImages, newImages = {}, {}
    for _, entry in ipairs(snapshot.entries) do
        if entry.previewImage and hs.fs.attributes(entry.previewImage, "mode") == "file" then
            local source = io.open(entry.previewImage, "rb")
            local bytes = source and source:read("*a")
            if source then source:close() end
            local path = bytes and state.imagePath()
            local target = path and io.open(path, "wb")
            local written = target and target:write(bytes)
            local closed = target and target:close()
            if not written or not closed then
                if path then os.remove(path) end
                for _, image in ipairs(newImages) do os.remove(image) end
                return readSnapshot(saved.path)
            end
            oldImages[#oldImages + 1] = entry.previewImage
            newImages[#newImages + 1] = path
            entry.previewImage = path
        end
    end
    local observed = snapshot.pid == pid and snapshot.observedChangeCount or hs.pasteboard.changeCount()
    local cleared = snapshot.pid == pid and snapshot.clearedChangeCount or nil
    if not state.save(snapshot.entries, observed, cleared) then
        for _, image in ipairs(newImages) do os.remove(image) end
        return readSnapshot(saved.path)
    end
    for _, image in ipairs(oldImages) do os.remove(image) end
    os.remove(saved.path)
    hs.settings.clear(legacyKey)
    return snapshot
end

function state.load()
    if not privateDirectory() then return end
    local snapshot = readSnapshot(historyPath) or migrateLegacy()
    if not snapshot then return end
    for index = #snapshot.entries, 1, -1 do
        local image = snapshot.entries[index].previewImage
        if image and hs.fs.attributes(image, "mode") ~= "file" then table.remove(snapshot.entries, index) end
    end
    if snapshot.pid ~= pid then
        -- Pasteboard counters belong to the current login session.
        snapshot.observedChangeCount = hs.pasteboard.changeCount()
        snapshot.clearedChangeCount = nil
    end
    return snapshot
end

return state
