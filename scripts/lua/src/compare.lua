local start_at = os.time()
local sMainLuaFilePath = GetMainLuaFilePath()
package.path = string.format("%s/../utils/?.lua;%s/../config/?.lua;", sMainLuaFilePath, sMainLuaFilePath) .. package
    .path
require "tools"
local config = require "config"


local git = config["git"][argv[3]]["src"]
local svn = config["svn"][argv[3]]["src"]

local gitInfo = GetFilesInfoInDirectoryRecursivelyMultiThreads(git)
local svnInfo = GetFilesInfoInDirectoryRecursivelyMultiThreads(svn)
-- PrintTableToJson(svnInfo)
local hasDiff = false
for file, gitFileMd5 in pairs(gitInfo) do
    local svnFileMd5 = svnInfo[string.gsub(file, git, svn, 1)]
    if svnFileMd5 == gitFileMd5 then
        gitInfo[file]                           = nil
        svnInfo[string.gsub(file, git, svn, 1)] = nil
    else
        hasDiff = true
    end
end
if not hasDiff then
    print("no different")
end
for fileName, _ in pairs(gitInfo) do
    local svnFileMd5 = svnInfo[string.gsub(fileName, git, svn, 1)]
    if svnFileMd5 then
        print(string.gsub(fileName, git, "", 1) .. " is different")
        gitInfo[fileName] = nil
        svnInfo[string.gsub(fileName, git, svn, 1)] = nil
    end
end
for fileName, _ in pairs(gitInfo) do
    print(string.gsub(fileName, git, "", 1) .. " only exists in git")
end
for fileName, _ in pairs(gitInfo) do
    print(string.gsub(fileName, svn, "", 1) .. " only exists in git")
end

local end_at = os.time()

print(string.format("run time : %s", end_at - start_at))
do
    return
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
