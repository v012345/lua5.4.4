local start_at = os.time()
local sMainLuaFilePath = GetMainLuaFilePath()
package.path = string.format("%s/../utils/?.lua;%s/../config/?.lua;", sMainLuaFilePath, sMainLuaFilePath) .. package
    .path
require "tools"
GetFilesOfDirectoryRecursively("D:/Closers.cocos/client/trunk/Resources")
local end_at = os.time()

print(string.format("run time : %s", end_at - start_at))
return