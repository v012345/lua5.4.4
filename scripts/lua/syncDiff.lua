local start_at = os.time()
local sMainLuaFilePath = GetMainLuaFilePath()
package.path = string.format("%s/utils/?.lua;%s/config/?.lua;", sMainLuaFilePath, sMainLuaFilePath) .. package.path
require "tools"
local config = require "config"
local md5File = sMainLuaFilePath .. "/config/" .. config[argv[3]][argv[4]][argv[5] .. "_md5"] .. ".lua"
local toSyncFiles = {}
local to = config[argv[7]][argv[4]][argv[5]]
local form = config[argv[3]][argv[4]][argv[5]]
local isDiff = (argv[8] == "diff")
if IsFileExist(md5File) then
    local md5Map = require(config[argv[3]][argv[4]][argv[5] .. "_md5"])

    for file, info in pairs(md5Map) do
        local last_write_time = GetFileLastModifiedTimestamp(file)
        if isDiff then
            if last_write_time > info.last_write_time then
                if info.md5 ~= GetFileMd5(file) then
                    toSyncFiles[#toSyncFiles + 1] = file
                end
            end
        else
            -- md5Map[file].last_write_time = last_write_time
            -- md5Map[file].md5 = GetFileMd5(file)
            toSyncFiles[#toSyncFiles + 1] = file
        end
    end
else
    print(string.format("%s donesn't exist", config[argv[3]][argv[4]][argv[5]] .. "_md5.lua"))
end

for _, file in pairs(toSyncFiles) do
    CopyFile(file, string.gsub(file, form, to, 1))
end

local end_at = os.time()
print(string.format("run time : %ss", end_at - start_at))
return
