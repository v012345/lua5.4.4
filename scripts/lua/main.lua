local a = coroutine.create(function() end)
local b = coroutine.wrap(function(p1, p2, p3)
    print(p1, p2, p3)
    coroutine.yield()
    print("jjj")
end)
b(1, 2)
b(1, 2)
xpcall(function()
    local luafile = "./test-lua.lua"
    local bytecode = require "bytecode"
    local toJson = require "utils.table2json"
    local h5js = io.open("./vue/lua.json", "w") or error()
    local luaByteCode = luac(luafile)
    local function trans(cl)
        for _, value in pairs(cl.p) do
            trans(value)
        end
        cl.code = bytecode:show(cl.code)
    end
    trans(luaByteCode)
    h5js:write(toJson(luaByteCode))
    h5js:close()
    print("done")
end, function(msg)
    print(msg)
end)
