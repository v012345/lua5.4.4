local a = 1
local b = 2
if a + b > 1 then
    print(1)
end
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
