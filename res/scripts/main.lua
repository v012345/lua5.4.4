local sMainLuaFilePath = GetMainLuaFilePath()
package.path = string.format("%s/utils/?.lua;%s/config/?.lua;", sMainLuaFilePath, sMainLuaFilePath) .. package.path
require "tools"
local md5 = require "md5"
local config = require "config"





PrintTableToJson(config)

local vvv = md5.sumhexa(md5, GetFileContent("C:\\Users\\Meteor\\Desktop\\aa.txt"))
PrintTableToJson(vvv)

PrintTableToJson(GetFileMd5("C:\\Users\\Meteor\\Desktop\\aa.txt"))
return
