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
local file = io.open("./dot/NDF.dot", "r") or error("can't open NDF.dot")
local content = file:read("a")
file:close()
local _, NFA = xpcall(dot2machine, function(msg)
    print(msg)
end, content)
-- NFA = NFA or {}
-- NFA:output(NFA, "C:\\Users\\Meteor\\Desktop\\configs\\ast1.dot")
-- local nfa2dfa = require "utils.nfa2dfa"
-- local _, DFA = xpcall(nfa2dfa, function(msg)
--     print(msg)
-- end, NFA)

-- xpcall(NFA.output, function(msg)
--     print(msg)
-- end, NFA, NFA, "C:\\Users\\Meteor\\Desktop\\configs\\ast2.dot")
