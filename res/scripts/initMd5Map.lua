local sMainLuaFilePath = GetMainLuaFilePath()
package.path = string.format("%s/utils/?.lua;%s/config/?.lua;", sMainLuaFilePath, sMainLuaFilePath) .. package.path
require "tools"
local config = require "config"
for _, versionControls in pairs(config) do
    for _, path in pairs(versionControls) do
        local md5File = sMainLuaFilePath .. "/config/" .. path.src_md5 .. ".lua"
        local info = GetFilesInfoInDirectoryRecursively(path.src)
        WriteConfigTableToFile(md5File, info)
        md5File = sMainLuaFilePath .. "/config/" .. path.res_md5 .. ".lua"
        info = GetFilesInfoInDirectoryRecursively(path.res)
        WriteConfigTableToFile(md5File, info)
    end
end
return
-- local md5File = sMainLuaFilePath .. "/config/" .. config.trunk.svn.src_md5 .. ".lua"
