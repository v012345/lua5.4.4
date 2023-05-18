require("bytedump")

-- local a = coroutine.create(function(a, b, c)
--     print(a, b, c)
-- end)

local function T(a, c, d, ...)
    local r, z, e, aa, aaa, aaaa = ...
    local tt = { ... }
    -- Bytedump:dump(GetOpCodes())
    local function b()
    end
    local y
    local x = 1
    return ...
end

local a, c = T(1, 2, 3, 4, 5, 6)
local a, c, d = T()

if T() then
    -- print("true")
end

for key, value in pairs(debug.getregistry()) do
    print(key, value)
    if type(value) == "table" then
        for k, v in pairs(value) do
            print("\t", k, v)
        end
    end
end

-- print(opmode(1, 1, 1, 1, 1, 1))

Bytedump:dump(GetOpCodes())
