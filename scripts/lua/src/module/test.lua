local test = {}
function test:run()
    print("test:run()")
    -- local start_at = os.time()
    -- local sMainLuaFilePath = GetMainLuaFilePath()
    -- package.path = string.format("%s/../utils/?.lua;%s/../config/?.lua;", sMainLuaFilePath, sMainLuaFilePath) .. package
    --     .path
    -- require "tools"
    -- local from = "D:/Closers.cocos/client/trunk/Resources"
    -- local info = GetFilesOfDirectoryRecursively(from)
    -- local map = {}
    -- for key, value in pairs(info) do
    --     map[value] = string.gsub(value, from, "D:/temp", 1)
    -- end
end

return test
