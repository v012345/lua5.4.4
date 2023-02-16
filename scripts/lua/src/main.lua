local start_at = os.time()
local s = GetMainLuaFilePath()
package.path = string.format("%s/../utils/?.lua;%s/../config/?.lua;%s/module/?.lua;", s, s, s) .. package.path
require "tools"

if argv["module"] then
    require(argv["module"]):run()
else
    (require "test"):run()
end

local end_at = os.time()
print(string.format("run time : %ss", end_at - start_at))
return
