local actions = require("modules.glass_launcher.actions.universal-actions")

local function executable(name)
    for _, directory in ipairs({ "/opt/homebrew/bin", "/usr/local/bin" }) do
        local path = directory .. "/" .. name
        if hs.fs.attributes(path, "mode") == "file" then return path end
    end
end

local poppler, exiftool = executable("pdftoppm"), executable("exiftool")

local function openPath(path, reveal)
    hs.task.new("/usr/bin/open", nil, reveal and { "-R", path } or { path }):start()
end

local function convertPDFToPNG(path, directory, name)
    local stem = directory .. "/" .. name:sub(1, -5) .. " PNG"
    local destination, suffix = stem, 2
    while not hs.fs.mkdir(destination) do
        if not hs.fs.symlinkAttributes(destination) then
            hs.alert.show("Could not create the PNG output folder")
            return
        end
        destination = ("%s %d"):format(stem, suffix)
        suffix = suffix + 1
    end

    local function finish(code)
        if code == 0 then
            openPath(destination)
            return
        end
        for entry in hs.fs.dir(destination) do
            if entry:match("^page%-%d+%.png$") then os.remove(destination .. "/" .. entry) end
        end
        hs.fs.rmdir(destination)
        hs.alert.show("Could not convert PDF to PNG")
    end
    local task = hs.task.new(poppler, finish,
        { "-png", "-r", "150", path, destination .. "/page" })
    if not task or not task:start() then finish(1) end
end

local function removeEXIF(path, directory, name)
    local stem, extension = name:match("^(.*)(%.[^.]+)$")
    local base = directory .. "/" .. stem .. " (no EXIF)"
    local destination, suffix = base .. extension, 2
    while hs.fs.symlinkAttributes(destination) do
        destination = ("%s %d%s"):format(base, suffix, extension)
        suffix = suffix + 1
    end
    local task = hs.task.new(exiftool, function(code)
        if code == 0 then
            openPath(destination, true)
        else
            hs.alert.show("Could not remove EXIF metadata")
        end
    end, { "-EXIF:all=", "-o", destination, path })
    if not task or not task:start() then hs.alert.show("Could not start ExifTool") end
end

local imageFormats = { jpg = true, jpeg = true, png = true, heic = true, heif = true,
    tif = true, tiff = true, webp = true }

local function extension(subject)
    return subject.path and hs.fs.attributes(subject.path, "mode") == "file"
        and subject.path:lower():match("%.([^/%.]+)$")
end

local function run(conversion, subject)
    local directory, name = subject.path:match("^(.*)/([^/]+)$")
    if directory then conversion(subject.path, directory, name) end
end

actions.register("file", {
    title = "Convert to PNG", symbol = "photo.on.rectangle",
    when = function(subject) return poppler and extension(subject) == "pdf" end,
    run = function(subject) run(convertPDFToPNG, subject) end,
})

actions.register("file", {
    title = "Remove EXIF metadata", symbol = "camera.filters",
    when = function(subject) return exiftool and imageFormats[extension(subject)] end,
    run = function(subject) run(removeEXIF, subject) end,
})
