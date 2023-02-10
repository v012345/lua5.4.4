local sMainLuaFilePath = GetMainLuaFilePath()
package.path = string.format("%s/utils/?.lua;%s/config/?.lua;", sMainLuaFilePath, sMainLuaFilePath) .. package.path
require "tools"
local config = require "config"
local md5File = sMainLuaFilePath .. "/config/" .. config.trunk.svn.src_md5 .. ".lua"





if IsFileExist(md5File) then
    local md5Map = require(config.trunk.svn.src_md5)
    for file, info in pairs(md5Map) do
        local l = GetFileLastModifiedTimestamp(file)
        if l > info.last_write_time then
            print(info.filename)
        end
    end
else
    local info = GetFilesInfoInDirectoryRecursively(config.trunk.svn.src)
    WriteConfigTableToFile(md5File, info)
end
return
