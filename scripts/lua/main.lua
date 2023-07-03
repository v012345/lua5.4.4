-- require "dot_parser.parser"
---@diagnostic disable-next-line
function main()
    -- local state = require "compiler.FA_State"
    -- ---@type function, function
    -- local FA_State_Matrix, FA_State_Matrix_Entry = table.unpack((require "compiler.FA_State_Matrix"))
    -- ---@type FA_State_Matrix
    -- local m = FA_State_Matrix()

    -- m:addEntry(FA_State_Matrix_Entry(
    --     state(1, nil, 3, 3, 4, "6"), "a", 2
    -- ))
    -- m:addEntry(FA_State_Matrix_Entry(
    --     state(2), "a", 2
    -- ))
    -- m:addEntry(FA_State_Matrix_Entry(
    --     state(2), "bb", 3
    -- ))
    -- m:addEntry(FA_State_Matrix_Entry(
    --     state(3), "bcb", 3
    -- ))
    -- -- print(m)

    -- -- do
    -- --     return
    -- -- end
    -- require "clua"
    -- require "lparser"
    -- require "lzio"
    -- ---@type Zio
    -- local z = new(Zio)
    -- local firstchar = zgetc(z)
    -- luaY_parser(nil, z, new(Mbuffer), nil, "test.lua", firstchar)


    -- -- io.write(tostring(a))
    -- local dot2machine = require "utils.dot2machine"
    -- local file = io.open("./dot/NDF.dot", "r") or error("can't open NDF.dot")
    -- local content = file:read("a")
    -- file:close()
    -- local _, NFA = xpcall(dot2machine, function(msg)
    --     print(msg)
    -- end, content)
    -- -- -- NFA = NFA or {}
    -- file = io.open("./build/ast1.dot", "w") or error("can't open ast1.dot")
    -- file:write(tostring(NFA))
    -- file:close()
    -- local t = require "utils.nfa2dfa"
    -- xpcall(t.nfa2dfa, function(msg)
    --     print(msg)
    -- end, NFA)
    -- local minimizeDFA = require "utils.minimizeDFA"

    -- file = io.open("./build/ast2.dot", "w") or error("can't open ast2.dot")
    -- file:write(tostring(NFA))
    -- file:close()
    -- minimizeDFA(NFA)
    -- file = io.open("./build/ast3.dot", "w") or error("can't open ast3.dot")
    -- file:write(tostring(NFA))
    -- file:close()
end

xpcall(main, function(msg)
    print(msg)
end)



-- xpcall(NFA.output, function(msg)
--     print(msg)
-- end, NFA, "C:\\Users\\Meteor\\Desktop\\configs\\ast2.dot")
