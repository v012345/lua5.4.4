local start_at = os.time()
local sMainLuaFilePath = GetMainLuaFilePath()
package.path = string.format("%s/../utils/?.lua;%s/../config/?.lua;", sMainLuaFilePath, sMainLuaFilePath) .. package
    .path
require "tools"
local config = require "config"

local git = config["git"][argv[3]][argv[4]]
local svn = config["svn"][argv[3]][argv[4]]

local gitInfo = GetFilesInfoInDirectoryRecursively(git)
local svnInfo = GetFilesInfoInDirectoryRecursively(svn)

for file, fileInfo in pairs(gitInfo) do
    local svnFile = svnInfo[string.gsub(file, git, svn, 1)]
    if svnFile and fileInfo.md5 == svnFile.md5 then
        gitInfo[file]                           = nil
        svnInfo[string.gsub(file, git, svn, 1)] = nil
    end
end

for key, value in pairs(svnInfo) do
    print(key)
end

for key, value in pairs(gitInfo) do
    print(key)
end

local end_at = os.time()

print(string.format("run time : %s", end_at - start_at))
return
