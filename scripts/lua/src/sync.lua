local start_at = os.time()
local sMainLuaFilePath = GetMainLuaFilePath()
package.path = string.format("%s/../utils/?.lua;%s/../config/?.lua;", sMainLuaFilePath, sMainLuaFilePath) .. package
    .path
require "tools"
local config = require "config"
local from = config[argv[3]][argv[4]][argv[5]]
local to = config[argv[7]][argv[4]][argv[5]]
local md5 = config[argv[3]][argv[4]][argv[5] .. "_md5"]

local md5File = sMainLuaFilePath .. "/../config/" .. md5 .. ".lua"

if IsFileExist(md5File) then
    local syncFiles = {}
    local md5Map = require(md5)

    for file, fileInfo in pairs(md5Map) do
        CopyFile(file, string.gsub(file, from, to, 1))
        if GetFileLastModifiedTimestamp(file) > fileInfo.last_write_time then
            syncFiles[#syncFiles+1] = file
        end
        print(string.format("copy %s", fileInfo.filename))
    end
    for _, file in pairs(syncFiles) do
        print(string.format("copy %s", file))
    end
    print(string.format("sync %s files", #syncFiles))
else
    local info = GetFilesInfoInDirectoryRecursively(from)
    WriteConfigTableToFile(md5File, info)
    local md5Map = require(md5)

    for file, fileInfo in pairs(md5Map) do
        CopyFile(file, string.gsub(file, from, to, 1))
        print(string.format("copy %s", fileInfo.filename))
    end
end



local end_at = os.time()

print(string.format("run time : %s", end_at - start_at))
return
