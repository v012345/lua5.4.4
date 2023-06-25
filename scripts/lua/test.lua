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

local dot2machine = require "utils.dot2machine"
local file = io.open("./dot/input.dot", "r") or error("can't open input.dot")
local content = file:read("a")
file:close()
local NFA = dot2machine(content) or {}
NFA:output(NFA, "C:\\Users\\Meteor\\Desktop\\configs\\ast.dot")
if NFA.output then
    print(".....")
end
