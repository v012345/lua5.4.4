require("bytedump")
local function a()
    return 1, 2, 3
end
print(a(), 4, a())

Bytedump:dump(GetOpCodes())
