-- require("utils.tools")
local lfs = require("lfs")
local JSON = require("utils.json2table")
local XML = require("utils.xml2table")
local file = io.open("config.json", "r") or error("can't read config")
local config = JSON(file:read("a")) or {}
file:close()
local images_map = {}
local function traverseDirectory(path, root, prefix)
    local map = images_map
    for entry in lfs.dir(path) do
        if entry ~= "." and entry ~= ".." then
            local filePath = path .. "/" .. entry
            local fileAttributes = lfs.attributes(filePath)

            if fileAttributes.mode == "directory" then
                traverseDirectory(filePath, root, prefix)
            elseif fileAttributes.mode == "file" then
                map[entry] = string.gsub(filePath, root, prefix)
            end
        end
    end
end
local function get_sheet_data(sheet)
    for _, child in pairs(sheet.children) do
        if child.name == "sheetData" then
            return child
        end
    end
end
local function get_sst(shared)
    if shared.name ~= "sst" then
        error("not sst")
    end
    local t = {}
    local i = 0
    for _, si in pairs(shared.children) do
        if si.children[1].name == "t" then
            t[i] = si.children[1].content
            i = i + 1
        else
            local s = {}
            for _, r in pairs(si.children) do
                for _, t1 in pairs(r.children) do
                    if t1.name == "t" then
                        s[#s + 1] = t1.content
                    end
                end
            end
            t[i] = table.concat(s)
            i = i + 1
        end
    end
    return t
end
local function checkout_string_level(string_data, mt, column)
    if string.find(string_data, "%^") then
        mt[column] = 3
    elseif string.find(string_data, "|") then
        if mt[column] then
            if mt[column] < 2 then
                mt[column] = 2
            end
        else
            mt[column] = 2
        end
    else
        if not mt[column] then
            mt[column] = 1
        end
    end
end
local function sheet_data_to_table(sheet_data, sharedStrings)
    local t = {}
    local mt = {}
    for i, row in pairs(sheet_data.children) do
        local r = {}
        for key, c in pairs(row.children) do
            if c.attributes.t == "s" then
                if c.children[1] then
                    r[#r + 1] = sharedStrings[tonumber(c.children[1].content)]
                    checkout_string_level(r[#r], mt, #r)
                end
            elseif c.attributes.t == "str" then
                for key, value in pairs(c.children) do
                    if value.name == "v" then
                        r[#r + 1] = value.content
                        checkout_string_level(r[#r], mt, #r)
                        break
                    end
                end
            else
                -- print(i, #r)
                for key, value in pairs(c.children) do
                    if value.name == "v" then
                        r[#r + 1] = value.content
                        checkout_string_level(r[#r], mt, #r)
                        break
                    end
                end
                -- print
            end
        end
        t[#t + 1] = #r > 0 and r or nil
    end
    setmetatable(t, mt)
    return t
end

local function convert_excel_to_table(sheet, shared)
    local sheet_data = get_sheet_data(sheet)
    local sst = get_sst(shared)
    local lua_table = sheet_data_to_table(sheet_data, sst)
    return lua_table
end

local function write_to_lua_file(toLua, table_name, data)
    local j = 0
    local function dump(t, o, q)
        if type(t) == 'table' then
            j = j + 1
            o:write('{\n')
            for k, v in pairs(t) do
                for i = 1, j, 1 do
                    o:write("    ")
                end
                if tonumber(k) then
                    o:write(string.format("[%s] = ", k))
                else
                    o:write(string.format("%s = ", k))
                end
                dump(v, o, true)
            end
            j = j - 1
            for i = 1, j, 1 do
                o:write("    ")
            end

            if q then
                o:write('},\n')
            else
                o:write('}\n')
            end
        elseif type(t) == "string" then
            local n = tonumber(t)
            if n then
                o:write(n)
            else
                o:write(string.format('"%s"', images_map[t] or t))
            end
            o:write(",")
            o:write("\n")
        end
    end
    local o = io.open(toLua, "w") or error("can't write")
    o:write(string.format("local %s = ", table_name))
    dump(data, o, false)
    o:write("\n")
    o:write("return " .. table_name)
    o:close()
end

local function create_id(lua_table)
    local game_table = {}
    local has_id = false
    for key, value in pairs(lua_table[1]) do
        if string.lower(key) == "id" then
            has_id = true
            break
        end
    end
    if not has_id then
        return lua_table
    end
    for key, value in pairs(lua_table) do
        for k, v in pairs(value) do
            if string.lower(k) == "id" then
                if tonumber(value[k]) then
                    game_table[v] = value
                end
                break
            end
        end
    end

    return game_table
end

local function lua_table_to_game_table(lua_table)
    local mt = getmetatable(lua_table)
    local game_table = {}
    local len = #lua_table[1]
    for i = 2, #lua_table, 1 do
        game_table[#game_table + 1] = {}
        for index, value in ipairs(lua_table[i]) do
            if index <= len then
                if mt[index] == 1 then
                    game_table[#game_table][lua_table[1][index]] = value
                elseif mt[index] == 2 then
                    local value2 = {}
                    for key in string.gmatch(value, "[^|]+") do
                        value2[#value2 + 1] = key
                    end
                    game_table[#game_table][lua_table[1][index]] = value2
                elseif mt[index] == 3 then
                    local value3 = {}
                    for key in string.gmatch(value, "[^%^]+") do
                        value3[#value3 + 1] = {}
                        for k in string.gmatch(key, "[^|]+") do
                            value3[#value3][#value3[#value3] + 1] = k
                        end
                    end
                    game_table[#game_table][lua_table[1][index]] = value3
                else
                    error("too many level")
                end
            end
        end
    end
    return game_table
end


local function main()
    print(">>> collecting images info >>>")
    for _, res in pairs(config.res) do
        print("traverse", res)
        traverseDirectory(res, res .. "/", "")
    end
    -- traverseDirectory(config.image)
    print("==============================")

    print(">>> collecting xls info >>>")
    local folder_path = config.xls_path
    local xls_modify_time = {}
    for entry in lfs.dir(folder_path) do
        if string.match(entry, "^.+%.xls$") then
            local filePath = folder_path .. "/" .. entry
            xls_modify_time[string.gsub(entry, ".xls", "")] = lfs.attributes(filePath, "modification")
        end
    end
    print("==============================")

    print(">>> collecting xlsx info >>>")

    local covert_to_xlsx = {}
    for file_name, modify_time in pairs(xls_modify_time) do
        local target = config.temp .. "\\" .. file_name .. ".xlsx"
        local source = config.xls_path .. "\\" .. file_name .. ".xls"
        local create_time = lfs.attributes(target, "modification")
        if not create_time then
            covert_to_xlsx[source] = target
        elseif create_time <= modify_time then
            covert_to_xlsx[source] = target
        end
    end

    print("==============================")
    print(">>> covert to xlsx >>>")
    for source, target in pairs(covert_to_xlsx) do
        local cmd = string.format(config.xls2xlsx_cmd, source, target)
        local handle = io.popen(cmd) or error("can't execute cmd")
        local output = handle:read("a")
        print("create", output, target)
        handle:close()
    end

    print("==============================")
    print(">>> convert to lua table >>>")
    local lua_tables = {}
    for _, xlsx in pairs(covert_to_xlsx) do
        local cmd = string.format(config.zip_cmd, xlsx, config.temp)
        local handle = io.popen(cmd) or error("can't execute unzip")
        handle:close()
        local f = io.open(config.temp .. "\\xl\\sharedStrings.xml", "r") or error("can't open sharedStrings.xml")
        local shared = f:read("a")
        f:close()
        f = io.open(config.temp .. "\\xl\\worksheets\\sheet1.xml", "r") or error("can't open sheet1.xml")
        local sheet1 = f:read("a")
        f:close()
        print("convert ok", xlsx)
        lua_tables[string.gsub(xlsx, "xlsx$", "lua", 1)] = convert_excel_to_table(XML(sheet1)[1], XML(shared)[1])
    end
    print("==============================")
    print(">>> convert to game table >>>")
    local game_tables = {}
    for xlsx_path, lua_table in pairs(lua_tables) do
        local game_table_name = string.sub(xlsx_path, #config.temp + 2, #xlsx_path - 4)
        print("convert ok", game_table_name)
        game_tables[game_table_name] = lua_table_to_game_table(lua_table)
    end
    print("==============================")
    print(">>> adjust game table id >>>")
    for game_table_name, game_table in pairs(game_tables) do
        print("adjust ok ", game_table_name)
        game_tables[game_table_name] = create_id(game_table)
    end
    print("==============================")
    print(">>> write game table to lua file >>>")
    for game_table_name, game_table in pairs(game_tables) do
        print("write ok", game_table_name)
        local target = config.lua_test_output .. "\\" .. game_table_name .. ".lua"
        write_to_lua_file(target, game_table_name, game_table)
    end
    print("==============================")
    print("bye bey")
end

return main
