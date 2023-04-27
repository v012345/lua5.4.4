require("bytedump")
local a = 0
local b = 2
a = 1 << b
a = 1 >> b
print(a)
Bytedump:dump(GetOpCodes())
