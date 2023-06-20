function main()
    print(1)
    require "clua"
    print(1)
    require "lparser"
    print(1)
    ---@type Zio
    local z = new(Zio)
    print(1)
    local firstchar = zgetc(z)
    luaY_parser(nil, z, nil, nil, "test.lua", firstchar)

    local a = {
        aa = {
            dd = 3
        },
        bb = 1,
        cc = 1,
    }
    local c = new(a)
    print(a.aa.dd)
    print(c.aa.dd)
    c.aa.dd = 4
    print(a.aa.dd)
    print(c.aa.dd)
end

xpcall(main, function(msg)
    print(msg)
end)

-- local b = 1
-- while b < 2 do
--     local a = 1
--     b = b + 1
-- end
-- if 3 < 1 then
--     local a = 1
-- end
-- local lLex = require("utils.lua_lex")
-- lLex:load("utils/json_lex.lua")
-- -- debug.sethook(function(a, b)
-- --     print(a, b)
-- -- end, "l", 0)
-- -- xpcall(lLex.test, function(a)
-- --     print("\n")
-- --     print(a)
-- -- end, lLex)
-- -- do
-- --     return
-- -- end
-- local lParser = require("utils.lua_parser")
-- lParser:init(lLex)
-- xpcall(lParser.test, function(a)
--     print("\n")
--     print(a)
-- end, lParser)
