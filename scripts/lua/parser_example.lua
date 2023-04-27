require("bytedump")
local b = 2
local a = 1
local c
if a > b then
    c = a > b
else
    c = a < b
    c = a <= b
    c = a >= b
    c = a == b
    c = a ~= b
end


Bytedump:dump(GetOpCodes())
