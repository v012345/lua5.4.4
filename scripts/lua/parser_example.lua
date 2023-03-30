function trace(event, line)
    local s = debug.getinfo(2).short_src
    -- print(s .. ":" .. line)
end

c = "54332555555555"

debug.sethook(trace, "l")

function add(a, b)
    return a + b
end

local result = add(1, 2)
print(result)

debug.sethook()
-- debug.debug()
for key, value in pairs(debug) do
    print(key, value )
end