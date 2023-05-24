require("bytedump")
require("utils.tools")
local JSON = require("utils.read_json")
local JS = require("utils.read_json")

print(JS == JSON)
-- debug.sethook(function(a, b)
--     print(a, b)
-- end, "l", 0)
JSON:open("C:\\Users\\Meteor\\Desktop\\New Text Document.json")

local r, j = JSON:parser()
if r then
    JSON:dump("C:\\Users\\Meteor\\Desktop\\o.txt")
end
-- Bytedump:dump(GetOpCodes())
