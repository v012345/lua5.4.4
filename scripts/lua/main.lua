local function main()
    local lfs = require "lfs"
    local res_path = "D:\\Closers.cocos\\resource\\ui\\branches\\handygame\\ko"
    local ui_path = res_path .. "\\cocosstudio\\ui"

    ---comment
    ---@param path string "ko"
    ---@param suffixed string "csd"
    ---@param last_modification table "csd"
    ---@return table<string,string>
    local function getFiles(path, suffixed, last_modification)
        local m = {}
        local folder = path
        local pattern = "^.+%." .. suffixed .. "$"
        for entry in lfs.dir(folder) do
            if entry ~= "." and entry ~= ".." then
                local filePath = folder .. "/" .. entry
                local fileAttributes = lfs.attributes(filePath)
                if fileAttributes.mode == "file" then
                    if string.match(string.lower(filePath), pattern) then
                        if not last_modification[entry] then
                            m[entry] = filePath
                        else
                            if lfs.attributes(filePath, "modification") > last_modification[entry] then
                                m[entry] = filePath
                            end
                        end
                    end
                end
            end
        end
        return m
    end
    local csd_files = getFiles(ui_path, "csd")
    lfs.chdir(ui_path)
    local function getSha1(path)
        local windows_path = string.gsub(path, "/", "\\")
        local cmd = string.format('certutil -hashfile "%s"', windows_path)
        local result = io.popen(cmd) or error("can't run " .. cmd)
        local _, r = result:read("l"), result:read("l")
        result:close()
        return r
    end
    local function file_exists(name)
        local f = io.open(name, "r")
        if f ~= nil then
            io.close(f)
            return true
        else
            return false
        end
    end

    if file_exists("build/ko.json") then
    else

    end
    print(lfs.currentdir())
    -- local json = require "utils.json2table"
    -- local json_file = io.open("build/csd.json", "r")
    -- ---@type any
    -- local csd_json = {}
    -- if json_file then
    --     csd_json = json(json_file:read("a"))
    --     json_file:close()
    -- else
    --     local tojson = require "utils.table2json"
    --     local t = {}
    --     for csd_name, csd_path in pairs(csd_files) do
    --         t[csd_name] = {
    --             modification = lfs.attributes(csd_path, "modification"),
    --             sha1 = getSha1(csd_path)
    --         }
    --     end
    --     local json_string = tojson(t)
    --     json_file = io.open("build/csd.json", "w") or error("can't open build/csd.json")
    --     json_file:write(json_string)
    --     json_file:close()
    --     return
    -- end
    -- print(">>> start >>>")
    -- for csd_name, csd_path in pairs(csd_files) do
    --     if csd_json[csd_name].modification < lfs.attributes(csd_path, "modification") and
    --         csd_json[csd_name].sha1 ~= getSha1(csd_path)
    --     then
    --         csd_json[csd_name].modification = lfs.attributes(csd_path, "modification")
    --         csd_json[csd_name].sha1 = getSha1(csd_path)
    --     end
    -- end
    -- local table2json = require "utils.table2json"
    -- local json_string = table2json(csd_json)
    -- local table2json_file = io.open("build/csd.json", "w") or error("can't open build/csd.json")
    -- table2json_file:write(json_string)
    -- table2json_file:close()
    -- local css = string.format("%s\\%s\\Closers_temp.ccs", csd_path, "ko")
    -- csd(ccs_temp, css)
    -- local game_res = "D:\\Closers.cocos\\client\\branches\\dzogame_sea\\Resources\\res_" .. lang
    -- local cocos_cmd =
    -- "\"C:\\Cocos\\Cocos Studio\\Cocos.Tool.exe\" publish -f %s -o %s -s -d Serializer_FlatBuffers"
    -- print(string.format(cocos_cmd, css, game_res))
    -- local exe_cmd = io.popen(string.format(cocos_cmd, css, game_res)) or error("can't execute " .. cocos_cmd)
    -- print(exe_cmd:read("a"))
    -- exe_cmd:close()
    print("<<< end replacing <<<")
end



xpcall(main, function(msg)
    print(msg)
end)
