require("bytedump")

-- local a = coroutine.create(function(a, b, c)
--     print(a, b, c)
-- end)

local function T()
    return true, false
end

local a, c = T()
local a, c, d = T()

if T() then
    print("true")
end

Bytedump:dump(GetOpCodes())
