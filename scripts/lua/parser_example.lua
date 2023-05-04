require("bytedump")
local function x()
    return true
end

if x() then
    local a = x
end

Bytedump:dump(GetOpCodes())
