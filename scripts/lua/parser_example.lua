function trace(event, line)
    local s = debug.getinfo(2).short_src
    print(s .. ":" .. line)
end

debug.sethook(trace, "l")

function add(a, b)
    return a + b
end

local result = add(1, 2)
print(result)