local tb1 = {}
local tb2 = {}

print(1)

tb1.__newindex = tb2
tb2.__newindex = tb1
print(1)
setmetatable(1, tb2)
setmetatable(tb2, tb1)
print(1)
tb1.x = 10
print(1)