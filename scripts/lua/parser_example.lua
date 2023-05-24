require("bytedump")
require("utils.tools")
local JSON = require("utils.read_json")
-- debug.sethook(function(a, b)
--     print(a, b)
-- end, "l", 0)
JSON:open("C:\\Users\\Meteor\\Desktop\\New Text Document.json")
JSON:dump()
local r, j = JSON:parser()
if r then
    PrintTableToJson(j)
end
-- Bytedump:dump(GetOpCodes())
