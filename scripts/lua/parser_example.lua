require("bytedump")

local x = {
    "jio",[2] = "jio"
}
x.a = {}
x.b = function(s)
    print(s)
end
x.c = function(s)
    print(s)
end
x.b(x[1])

Bytedump:dump(GetOpCodes())
