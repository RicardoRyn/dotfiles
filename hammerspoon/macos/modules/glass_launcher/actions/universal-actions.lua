local actions = {}
local definitions = { file = {}, text = {}, image = {} }

function actions.register(kind, definition)
    local list = assert(definitions[kind], "Expected file, text, or image")
    assert(type(definition.title) == "string" and definition.title ~= "", "Expected an action title")
    assert(type(definition.run) == "function", "Expected an action handler")
    assert(definition.when == nil or type(definition.when) == "function", "Expected an availability predicate")
    list[#list + 1] = definition
end

function actions.rows(kind, subject)
    local rows = {}
    for _, definition in ipairs(definitions[kind]) do
        if not definition.when or definition.when(subject) then
            rows[#rows + 1] = {
                title = definition.title,
                subtitle = definition.keyword,
                searchKeyword = definition.keyword and definition.keyword:lower(),
                symbol = definition.symbol,
                run = function() definition.run(subject) end,
            }
        end
    end
    return rows
end

return actions
