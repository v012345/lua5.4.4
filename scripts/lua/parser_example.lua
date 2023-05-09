require("bytedump")
local t = {
    XXX = 1,
    QQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQ = 1
}
t.QQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQ = 2
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

t.XXX = 2

print(t.QQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQ)

Bytedump:dump(GetOpCodes())
