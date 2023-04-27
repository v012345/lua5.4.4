require("bytedump")
local mt = {
    __len = function()
        return 1
    end,
    __add = function(a, b)
        return 2
    end
}
local t = {}
setmetatable(t, mt)
print(111111111111 + t)
local x
for i = 1, 10, 1 do
    local j = 1
    x = function()
        j = j + 1
        return j
    end
end
x()



Bytedump:dump(GetOpCodes())
