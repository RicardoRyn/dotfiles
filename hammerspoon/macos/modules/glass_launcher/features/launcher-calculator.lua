local calculator = {}
local precedence = { ["+"] = 1, ["-"] = 1, ["*"] = 2, ["/"] = 2, ["^"] = 4 }
local operations = {
    ["+"] = function(a, b) return a + b end,
    ["-"] = function(a, b) return a - b end,
    ["*"] = function(a, b) return a * b end,
    ["/"] = function(a, b) return a / b end,
    ["^"] = function(a, b) return a ^ b end,
}
local functions = { sqrt = math.sqrt, abs = math.abs }

function calculator.evaluate(query)
    if #query > 256 then return end
    local text = query:lower():gsub("×", "*"):gsub("÷", "/"):gsub("−", "-")
    if not text:find("[+*/^()%-]") then return end
    local pos = 1
    local function token(pattern)
        local _, last, value = text:find("^%s*(" .. pattern .. ")", pos)
        if last then pos = last + 1 end
        return value
    end

    local expression
    expression = function(minimum)
        local left
        local sign = token("[+-]")
        if sign then
            left = expression(3)
            if sign == "-" then left = -left end
        elseif token("%(") then
            left = expression(1)
            assert(token("%)"))
        else
            local name = token("%a+")
            if name then
                local fn = assert(functions[name])
                assert(token("%("))
                left = fn(expression(1))
                assert(token("%)"))
            else
                left = assert(tonumber(token("%d+%.?%d*") or token("%.%d+")))
            end
        end

        while true do
            local previous = pos
            local operator = token("[+*/^%-]")
            local priority = precedence[operator]
            if not priority or priority < minimum then
                pos = previous
                return left
            end
            local right = expression(operator == "^" and priority or priority + 1)
            left = operations[operator](left, right)
        end
    end

    local ok, result = pcall(expression, 1)
    if ok and text:sub(pos):match("^%s*$") and result == result and math.abs(result) < math.huge then
        return result
    end
end

function calculator.currency(query)
    local amount, base, quote = query:lower():match("^([+-]?[%d.]+)%s*(%a%a%a)%s+to%s+(%a%a%a)$")
    amount = tonumber(amount)
    if amount and math.abs(amount) < math.huge then
        return amount, base:upper(), quote:upper()
    end
end

function calculator.format(value, decimals)
    local raw = string.format(decimals and "%." .. decimals .. "f" or "%.12g", value)
    local sign, integer, rest = raw:match("^(-?)(%d+)(.*)$")
    if not integer or rest:find("e", 1, true) then return raw, raw end
    local grouped = integer:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
    return sign .. grouped .. rest, raw
end

return calculator
