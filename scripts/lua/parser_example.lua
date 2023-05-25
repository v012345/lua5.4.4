require("bytedump")
require("utils.tools")
local JSON = require("utils.read_json")
local r1 = JSON("C:\\Users\\Meteor\\Desktop\\New Text Document.json")
-- local r2 = JSON("C:\\Users\\Meteor\\Desktop\\New Text Document.json")
-- print(r1 == r2)
-- if r then
--     JSON:dump("C:\\Users\\Meteor\\Desktop\\o.txt")
-- end
Bytedump:dump(GetOpCodes())
