local contentSearch = {}
local scope = require("modules.glass_launcher.features.launcher-search-scope")
local resultLimit = 50

function contentSearch.start(term, update)
    local escaped = term:gsub('([\\"*?])', '\\%1')
    local args = scope.spotlightArguments('kMDItemTextContent == "*' .. escaped .. '*"cd')
    if not args then
        update({}, true)
        return function() end
    end

    local results, seen, tail = {}, {}, ""
    local stopped, task, timeout
    local function cancel()
        if stopped then return end
        stopped = true
        if timeout then timeout:stop() end
        if task and task:isRunning() then task:terminate() end
    end
    local function finish(timedOut)
        if stopped then return end
        cancel()
        update(results, true, timedOut)
    end

    task = hs.task.new("/usr/bin/mdfind", function()
        -- Hammerspoon delivers any final stream chunk after its exit callback.
        hs.timer.doAfter(0, finish)
    end, function(_, output)
        if stopped then return false end
        local previous = #results
        tail = tail .. output
        local start = 1
        while #results < resultLimit do
            local ending = tail:find("\0", start, true)
            if not ending then break end
            local path = tail:sub(start, ending - 1)
            if path ~= "" and not seen[path] and scope.searchablePath(path) then
                seen[path] = true
                results[#results + 1] = { path = path, kind = path:lower():match("%.pdf$") and "PDF" or "Document" }
            end
            start = ending + 1
        end
        tail = tail:sub(start)
        if #results == resultLimit then
            finish()
            return false
        end
        if #results > previous then update(results, false) end
        return true
    end, args)
    if task and task:start() then
        timeout = hs.timer.doAfter(8, function() finish(true) end)
    else
        finish()
    end
    return cancel
end

return contentSearch
