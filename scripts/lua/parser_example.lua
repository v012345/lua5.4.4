require("bytedump")

local x = {}
x.a = {}
x.b = function(s)
    print(s)
end
x.c = function(s)
    print(s)
end
x.b("23")

Bytedump:dump(GetOpCodes())
