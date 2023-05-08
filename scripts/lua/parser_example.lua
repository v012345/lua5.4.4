require("bytedump")
local a = ...
print(a)
local function x()
    return true
end

if x() then
    local a = x
end

local i = 0
while i < 10 do
    i = i + 1
end

Bytedump:dump(GetOpCodes())
