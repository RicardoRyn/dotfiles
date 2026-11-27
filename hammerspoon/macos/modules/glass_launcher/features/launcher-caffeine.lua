local power = hs.caffeinate
local caffeine = {}
local timer
local activityID

local function keepScreenActive()
    local session = power.sessionProperties()
    if session and not session.CGSSessionScreenIsLocked and session.kCGSSessionOnConsoleKey ~= false then
        activityID = power.declareUserActivity(activityID)
    end
end

function caffeine.enabled()
    return timer ~= nil
end

function caffeine.toggle()
    if timer then
        timer:stop()
        timer = nil
        power.set("displayIdle", false)
        return false
    end
    power.set("displayIdle", true)
    keepScreenActive()
    timer = hs.timer.doEvery(15, keepScreenActive)
    return true
end

return caffeine
