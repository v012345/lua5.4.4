require("bytedump")
local a = 0
local b = 2
a = b | 111111111111111
print(a)
Bytedump:dump(GetOpCodes())
