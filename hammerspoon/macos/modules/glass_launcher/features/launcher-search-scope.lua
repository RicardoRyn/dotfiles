local home = os.getenv("HOME")
local scope = {}
scope.appFolders = {
    "/Applications",
    home .. "/Applications",
    "/System/Applications",
    "/System/Applications/Utilities",
}
local folders = {
    home,
    home .. "/Library/Mobile Documents/com~apple~CloudDocs",
}
local function searchablePath(path)
    local library = home .. "/Library/"
    local cloud = folders[2]
    if path:sub(1, #library) == library and path ~= cloud
        and path:sub(1, #cloud + 1) ~= cloud .. "/" then return false end
    for part in path:gmatch("[^/]+") do
        if part:sub(1, 1) == "." or part:lower():match("%.app$") then return false end
    end
    return true
end
scope.searchablePath = searchablePath
local extensions = {
    "pdf", "doc", "docx", "docm", "xls", "xlsx", "xlsm", "ppt", "pptx", "pptm",
    "pages", "numbers", "key", "odt", "ods", "odp", "rtf", "rtfd", "epub",
}
local predicates = {}
for _, extension in ipairs(extensions) do
    predicates[#predicates + 1] = 'kMDItemFSName == "*.' .. extension .. '"c'
end
scope.documents = "(" .. table.concat(predicates, " || ") .. ")"

function scope.spotlightArguments(predicate, includeFolders)
    local args = { "-0" }
    for _, folder in ipairs(folders) do
        if hs.fs.attributes(folder, "mode") == "directory" then
            args[#args + 1] = "-onlyin"
            args[#args + 1] = folder
        end
    end
    if #args == 1 then return end
    local types = scope.documents
    if includeFolders then types = '(' .. types .. ' || kMDItemContentType == "public.folder")' end
    args[#args + 1] = predicate and (types .. " && (" .. predicate .. ")") or types
    return args
end

local index, refreshTask, refreshedAt
local refreshInterval = 30

function scope.warmPathIndex()
    if refreshTask or (refreshedAt and hs.timer.absoluteTime() - refreshedAt < refreshInterval * 1e9) then return end
    local args = scope.spotlightArguments(nil, true)
    if not args then return end
    local task
    local nextIndex, seen, remainder = {}, {}, ""
    local function collect(output)
        if not output or output == "" then return end
        local data = remainder .. output
        local offset = 1
        while true do
            local stop = data:find("%z", offset)
            if not stop then break end
            local path = data:sub(offset, stop - 1)
            if path:sub(1, 1) == "/" and not seen[path] and searchablePath(path) then
                nextIndex[#nextIndex + 1] = { path = path, lower = path:lower() }
                seen[path] = true
            end
            offset = stop + 1
        end
        remainder = data:sub(offset)
    end
    task = hs.task.new("/usr/bin/mdfind", function(code, output)
        if refreshTask ~= task then return end
        if #nextIndex == 0 then collect(output) end
        refreshedAt = hs.timer.absoluteTime()
        if code == 0 then index = nextIndex end
        refreshTask = nil
    end, function(_, output)
        collect(output)
        return true
    end, args)
    if task and task:start() then refreshTask = task end
end

function scope.matchPaths(terms, accept, limit)
    scope.warmPathIndex()
    local matches = {}
    for _, entry in ipairs(index or {}) do
        local found = true
        for _, term in ipairs(terms) do
            if not entry.lower:find(term, 1, true) then found = false; break end
        end
        if found and accept(entry.path) and hs.fs.attributes(entry.path, "mode") then
            matches[#matches + 1] = entry.path
            if #matches >= limit then break end
        end
    end
    return matches
end

return scope
