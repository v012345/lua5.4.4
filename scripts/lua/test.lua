---@diagnostic disable-next-line
function main()
    require "clua"
    require "lparser"
    require "lzio"
    ---@type Zio
    local z = new(Zio)
    local firstchar = zgetc(z)
    luaY_parser(nil, z, new(Mbuffer), nil, "test.lua", firstchar)


    -- io.write(tostring(a))
    local dot2machine = require "utils.dot2machine"
    local file = io.open("./dot/NDF.dot", "r") or error("can't open NDF.dot")
    local content = file:read("a")
    file:close()
    local _, NFA = xpcall(dot2machine, function(msg)
        print(msg)
    end, content)
    -- -- NFA = NFA or {}
    file = io.open("../../../ast1.dot", "w") or error("can't open ast1.dot")
    file:write(tostring(NFA))
    file:close()
    local t = require "utils.nfa2dfa"
    xpcall(t.nfa2dfa, function(msg)
        print(msg)
    end, NFA)
    local minimizeDFA = require "utils.minimizeDFA"
    minimizeDFA(NFA)
    file = io.open("../../../ast2.dot", "w") or error("can't open ast2.dot")
    file:write(tostring(NFA))
    file:close()
end

xpcall(main, function(msg)
    print(msg)
end)



-- xpcall(NFA.output, function(msg)
--     print(msg)
-- end, NFA, "C:\\Users\\Meteor\\Desktop\\configs\\ast2.dot")
