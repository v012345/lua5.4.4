require("bytedump")
local t = {}
local a = 0
local b = 2
local c = a < 1
local c = a | b
local c = not a
local c = ~b
local c = -b
local c = #t
local c = a - b
local c = a % b
local c = a ^ b
print(a)
Bytedump:dump(GetOpCodes())
