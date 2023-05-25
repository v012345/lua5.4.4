require("bytedump")
require("utils.tools")
local JSON = require("utils.read_json")
local r1 = JSON("C:\\Users\\Meteor\\Desktop\\New Text Document.json")
local r2 = JSON("C:\\Users\\Meteor\\Desktop\\New Text Document.json")
print(r1() == r2())
print(type(r1))
print(type(r2))
-- if r then
--     JSON:dump("C:\\Users\\Meteor\\Desktop\\o.txt")
-- end
Bytedump:dump(GetOpCodes())


local function c()
    local counter = 1
    return function()
        counter = counter + 1
        return counter
    end
end

local counter1 = c()
local counter2 = c()
print(counter1())
print(counter1())
print(counter2())
print(counter2())
