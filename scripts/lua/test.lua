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


local m = matirx()
m["a"] = "aa"
m["b"] = "bb"
m["c"] = "cc"
m[set({ "a", "c" })] = "ac"
m[set({ "a", "b" })] = "bc"
-- print(set({ "a", "c" }) == set({ "a", "b" }))
for key, value in pairs(m) do
    print("key :", key, "value :", value)
end
-- print(m[set({ "a", "b" })])
-- print(m[set({ "a", "c" })])
