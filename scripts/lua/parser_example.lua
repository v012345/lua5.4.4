-- require("bytedump")


-- local function a()
--     local b = 1
--     Bytedump:dump(GetOpCodes())
--     return function()
--         Bytedump:dump(GetOpCodes())
--         b = b + 1
--         return b
--     end
-- end
-- local c = a()
-- c()
-- require("utils.tools")
local f = io.open("C:\\Users\\Meteor\\Desktop\\UiWorldBossMain.csd", "r")
local s = f and f:read("a") or ""
local xml = require("utils.xml2table")
local b = xml(s)
print(#b.root)
-- local c = xml("22222")
-- print(b.xml_string)
-- print(c.xml_string)
-- xml:parser(s)

-- --
-- -- local t = {}
-- -- if f then
-- --     local x = f:read("n")

-- --     while x do
-- --         if t[x] then
-- --             t[x] = t[x] + 1
-- --         else
-- --             t[x] = 1
-- --         end
-- --         x = f:read("n")
-- --     end
-- -- end
-- -- for key, value in pairs(t) do
-- --     print(key, value)
-- -- end



-- -- local JSON = require("utils.read_json")
-- -- -- -- print(type(JSON))
-- -- local s = os.clock()
-- -- JSON:parser("C:\\Users\\Meteor\\Desktop\\New Text Document.json")

-- -- JSON:dump("C:\\Users\\Meteor\\Desktop\\o.txt")
-- -- local e = os.clock()
-- -- print(e - s)


-- -- local a
-- -- while a do
-- --     print(a)
-- -- end

-- -- local r2 = JSON("C:\\Users\\Meteor\\Desktop\\New Text Document.json")
-- -- print(r1() == r2())
-- -- print(r1)
-- -- print(type(r1))
-- -- print(type(r2))
-- -- if r then
-- --
-- -- end
-- Bytedump:dump(GetOpCodes())





-- -- local function c()
-- --     local counter = 1
-- --     return function()
-- --         counter = counter + 1
-- --         return counter
-- --     end
-- -- end

-- -- local counter1 = c()
-- -- local counter2 = c()
-- -- print(counter1())
-- -- print(counter1())
-- -- print(counter2())
-- -- print(counter2())
-- -- local tools = { [1] = 2, [3] = 2, a = 2 }
-- -- local a = #tools
