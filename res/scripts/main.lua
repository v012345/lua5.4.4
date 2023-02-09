-- -- 打开文件（这个文件保存的是命令dir的结果）
-- local myfile = io.popen("dir /T:W  C:\\Users\\Meteor\\Desktop\\NightOwlTools\\AdjustUI\\audit_tables_v2\\rule.json", "r")
-- if nil == myfile then
--     print("open file for dir fail")
-- end
-- print(package.path)
-- print(debug.getinfo(1).source:match("@?(.*/)"))
---把表转成可读字符串
---@param table any
---@return string
function PrintTable(table)
    local function dump(o)
        if type(o) == 'table' then
            local s = '{ '
            for k, v in pairs(o) do
                if type(k) ~= 'number' then k = '"' .. k .. '"' end
                s = s .. '[' .. k .. '] = ' .. dump(v) .. ','
            end
            return s .. '} '
        else
            return tostring(o)
        end
    end
    print(dump(table))
end

PrintTable(GetFilesInfoInDirectory("C:\\Users\\Meteor\\Desktop\\NightOwlTools\\AdjustUI\\audit_tables_v2"))




print(GetFileLastModifiedTimestamp("C:\\Users\\Meteor\\Desktop\\NightOwlTools\\AdjustUI\\audit_tables_v2\\rule.json"))

-- print("\n======commond dir result:")
-- -- 读取文件内容
-- for cnt in myfile:lines() do
--     print(cnt)
-- end
    [[
    C:\Users\Meteor\Desktop\NightOwlTools\Lua\build\utils\LoadConfigFromLuaScripts\Debug\lua\?.lua;C:\Users\Meteor\Desktop\NightOwlTools\Lua\build\utils\LoadConfigFromLuaScripts\Debug\lua\?\init.lua;C:\Users\Meteor\Desktop\NightOwlTools\Lua\build\utils\LoadConfigFromLuaScripts\Debug\?.lua;C:\Users\Meteor\Desktop\NightOwlTools\Lua\build\utils\LoadConfigFromLuaScripts\Debug\?\init.lua;C:\Users\Meteor\Desktop\NightOwlTools\Lua\build\utils\LoadConfigFromLuaScripts\Debug\..\share\lua\5.4\?.lua;C:\Users\Meteor\Desktop\NightOwlTools\Lua\build\utils\LoadConfigFromLuaScripts\Debug\..\share\lua\5.4\?\init.lua;.\?.lua;.\?\init.lua
]]




-- -- 关闭文件
-- myfile:close()


-- local secondfile = io.popen("ipconfig")
-- if nil == secondfile then
--     print("open file for ipconfig fail")
-- end

-- print("\n======commond ipconfig result:")
-- -- 读取文件内容
-- local content = secondfile:read("*a")
-- print(content)

-- -- 关闭文件
-- secondfile:close()
