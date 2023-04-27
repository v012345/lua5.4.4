require("bytedump")
local a = 0
local b = 2
local c = a & b
local c = a | b
local c = not a
local c = a ~ b
local c = a - b
local c = a % b
local c = a ^ b
print(a)
Bytedump:dump(GetOpCodes())
