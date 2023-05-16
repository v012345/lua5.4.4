require("bytedump")

-- local a = coroutine.create(function(a, b, c)
--     print(a, b, c)
-- end)

local function T()
    Bytedump:dump(GetOpCodes())
    local function b()
    end
    local y
    local x = 1
    return x, b()
end

local a, c = T()
local a, c, d = T()

if T() then
    -- print("true")
end



-- print(opmode(1, 1, 1, 1, 1, 1))

Bytedump:dump(GetOpCodes())
