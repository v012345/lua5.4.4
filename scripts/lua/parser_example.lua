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



Bytedump:dump(GetOpCodes())
