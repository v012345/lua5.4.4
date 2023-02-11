local start_at = os.time()
local sMainLuaFilePath = GetMainLuaFilePath()
package.path = string.format("%s/utils/?.lua;%s/config/?.lua;", sMainLuaFilePath, sMainLuaFilePath) .. package.path
require "tools"
local config = require "config"
local md5File = sMainLuaFilePath .. "/config/" .. config[argv[3]][argv[4]][argv[5] .. "_md5"] .. ".lua"
local folder = config[argv[3]][argv[4]][argv[5]]
local info = GetFilesInfoInDirectoryRecursively(folder)
WriteConfigTableToFile(md5File, info)
local end_at = os.time()
print(string.format("run time : %ss", end_at - start_at))
return
