-- local start_at = os.time()
-- local sMainLuaFilePath = GetMainLuaFilePath()
-- package.path = string.format("%s/../utils/?.lua;%s/../config/?.lua;", sMainLuaFilePath, sMainLuaFilePath) .. package
--     .path
-- require "tools"
-- CopyFileMultiThreads(GetFilesOfDirectoryRecursively("D:/Closers.cocos/client/trunk/Resources/src"))

-- local end_at = os.time()

-- print(string.format("run time : %s", end_at - start_at))


local share_module = {
    qq = {
        qzone = {
            img = function()
            end,
            text = function(message)
                print("share with content:" .. tostring(message))
            end
        },
        chat = {

        }
    }
}

local share_protocal = function(module, method, text)
    local invoke_fun = module
    local t = string.gsub(method, '[^\\.]+', function(w)
        invoke_fun = invoke_fun[w]
    end)

    print("share_protocal after gsub:" .. tostring(invoke_fun))
    invoke_fun(text)
end

share_protocal(share_module, "qq.qzone.text", "hello world")

-- output
--[[
    share with content:hello world
]]
