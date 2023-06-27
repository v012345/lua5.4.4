---@diagnostic disable-next-line
function main()
    require "clua"
    require "lparser"
    require "lzio"
    ---@type Zio
    local z = new(Zio)
    local firstchar = zgetc(z)
    luaY_parser(nil, z, new(Mbuffer), nil, "test.lua", firstchar)
end

xpcall(main, function(msg)
    print(msg)
end)



local set = require "utils.set"
local matirx = require "utils.matrix"
local a = set(set("12"))
local b = set({ "12", "firstchar" })

for key, value in pairs(b) do
    print(key, value)
end

local m = matirx()
m[a] = matirx()
m[a][2] = "23412"
print(m[a][2])
print(m[b][2])
