require("bytedump")
require("utils.tools")


local JSON = require("utils.read_json")
-- print(type(JSON))
local s = os.clock()
JSON:parser("C:\\Users\\Meteor\\Desktop\\New Text Document.json")

JSON:dump("C:\\Users\\Meteor\\Desktop\\o.txt")
local e = os.clock()
print(e - s)
-- local r2 = JSON("C:\\Users\\Meteor\\Desktop\\New Text Document.json")
-- print(r1() == r2())
-- print(r1)
-- print(type(r1))
-- print(type(r2))
-- if r then
--
-- end
Bytedump:dump(GetOpCodes())


-- local function c()
--     local counter = 1
--     return function()
--         counter = counter + 1
--         return counter
--     end
-- end

-- local counter1 = c()
-- local counter2 = c()
-- print(counter1())
-- print(counter1())
-- print(counter2())
-- print(counter2())
local tools = { [1] = 2, [3] = 2, a = 2 }
local a = #tools
