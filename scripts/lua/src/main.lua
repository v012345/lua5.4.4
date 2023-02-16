local start_at = os.time()
local sMainLuaFilePath = GetMainLuaFilePath()
package.path = string.format(
        "%s/../utils/?.lua;%s/../config/?.lua;%s/module/?.lua;",
        sMainLuaFilePath,
        sMainLuaFilePath,
        sMainLuaFilePath) .. package
    .path
require "tools"

if argv[3] then
    local scprit = require(argv[3])
    if scprit then
        scprit:run()
    end
else
    local scprit = require "test"
    if scprit then
        scprit:run()
    end
end

local end_at = os.time()
print(string.format("run time : %ss", end_at - start_at))
return
