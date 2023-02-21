--- 脚本的入口文件
local start_at = os.time()
-- print(package.path)
-- local s = GetMainLuaFilePath()
package.path = "./utils/?.lua;./config/?.lua;./src/module/?.lua;" .. package.path
require "tools"
-- local a = require "test"
-- a:run()
-- (require "test"):run()
-- if argv["module"] then
--     require(argv["module"]):run()
-- else
--     (require "test"):run()
-- end
-- print("script main.lua")

local a =  XML:new("philjfiajfiaef")
print(a:GetPath())
a = nil

print(argv[1])
local end_at = os.time()
print(string.format("run time : %ss", end_at - start_at))
return
