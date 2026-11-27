local colors = {}

local function parse(query)
    local hex = query:match("^#(%x%x%x%x%x%x)$")
    if not hex then
        local r, g, b = query:match("^#(%x)(%x)(%x)$")
        if r then hex = r .. r .. g .. g .. b .. b end
    end
    if hex then
        return "hex", tonumber(hex:sub(1, 2), 16) / 255,
            tonumber(hex:sub(3, 4), 16) / 255, tonumber(hex:sub(5, 6), 16) / 255
    end

    query = query:lower()
    local body = query:match("^rgb%s*%((.*)%)$") or query:match("^rgb%s+(.+)$")
    if not body then return end
    local a, b, c = body:match("^%s*([%d.]+%%?)%s*,%s*([%d.]+%%?)%s*,%s*([%d.]+%%?)%s*$")
    if not a then return end
    local percentage = a:sub(-1) == "%"
    local limit = percentage and 100 or 255
    local function channel(value)
        if (value:sub(-1) == "%") ~= percentage then return end
        local number = tonumber((value:gsub("%%$", "")))
        if number and number <= limit then return number / limit end
    end
    local r, g, blue = channel(a), channel(b), channel(c)
    if r and g and blue then return percentage and "percent" or "rgb", r, g, blue end
end

local function round(value)
    return math.floor(value + 0.5)
end

local function decimal(value)
    return (string.format("%.3f", value):gsub("0+$", ""):gsub("%.$", ""))
end

function colors.choices(query)
    local kind, r, g, b = parse(query)
    if not kind then return end

    local red, green, blue = round(r * 255), round(g * 255), round(b * 255)
    local swatch = red * 65536 + green * 256 + blue
    local highest, lowest = math.max(r, g, b), math.min(r, g, b)
    local delta, lightness = highest - lowest, (highest + lowest) / 2
    local hue, saturation, hsvSaturation = 0, 0, 0
    if delta > 0 then
        if highest == r then
            hue = ((g - b) / delta) % 6
        elseif highest == g then
            hue = (b - r) / delta + 2
        else
            hue = (r - g) / delta + 4
        end
        hue = hue / 6
        saturation = delta / (1 - math.abs(2 * lightness - 1))
        hsvSaturation = delta / highest
    end

    local css = {
        hex = { string.format("#%06X", swatch), "Hexadecimal" },
        rgb = { string.format("rgb(%d, %d, %d)", red, green, blue), "RGB" },
        percent = { string.format("rgb(%d%%, %d%%, %d%%)", round(r * 100), round(g * 100), round(b * 100)), "RGB Percent" },
    }
    local choices = {}
    local function add(value, label)
        choices[#choices + 1] = { title = value, subtitle = label, copyValue = value, swatch = swatch }
    end
    local function addCSS(format)
        local entry = css[format]
        add(entry[1], "CSS · " .. entry[2])
    end
    addCSS(kind)
    for _, format in ipairs({ "rgb", "percent", "hex" }) do
        if format ~= kind then addCSS(format) end
    end
    add(string.format("hsl(%d, %d%%, %d%%)", round(hue * 360) % 360,
        round(saturation * 100), round(lightness * 100)), "CSS · HSL")

    local rgb = string.format("Red:%s green:%s blue:%s alpha:1", decimal(r), decimal(g), decimal(b))
    local hsb = string.format("Hue:%s saturation:%s brightness:%s alpha:1",
        decimal(hue), decimal(hsvSaturation), decimal(highest))
    if delta == 0 then
        add("[NSColor colorWithCalibratedWhite:" .. decimal(r) .. " alpha:1]", "NSColor · Calibrated White")
        add("[NSColor colorWithDeviceWhite:" .. decimal(r) .. " alpha:1]", "NSColor · Device White")
    end
    for _, space in ipairs({ "Calibrated", "Device" }) do
        add("[NSColor colorWith" .. space .. rgb .. "]", "NSColor · " .. space .. " RGB")
        add("[NSColor colorWith" .. space .. hsb .. "]", "NSColor · " .. space .. " HSB")
    end
    add("[UIColor colorWith" .. rgb .. "]", "UIColor · RGB")
    return choices
end

return colors
