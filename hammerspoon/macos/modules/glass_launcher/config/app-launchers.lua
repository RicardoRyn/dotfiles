-- The shared modifiers plus the configured key open or focus the app.
local mods = { "ctrl" }
local apps = {
    -- ["1"] = { name = "Rex Beta", bundleID = "com.superlogical.rex" },
    -- ["2"] = { name = "Safari", bundleID = "com.apple.Safari" },
}

for key, app in pairs(apps) do
    hs.hotkey.bind(mods, key, function()
        if not hs.application.launchOrFocusByBundleID(app.bundleID) then
            hs.alert.show("Could not open " .. app.name)
        end
    end)
end
