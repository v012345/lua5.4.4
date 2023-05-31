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
local function sheet_data_to_table(sheet_data, sharedStrings)
    local t = {}
    for i, row in pairs(sheet_data.children) do
        local r = {}
        for key, c in pairs(row.children) do
            if c.attributes.t == "s" then
                if c.children[1] then
                    r[#r + 1] = sharedStrings[tonumber(c.children[1].content)]
                end
            else
                -- print(i, #r)
                if c.children[1] then
                    r[#r + 1] = c.children[1].content
                end
                -- print
            end
        end
        t[#t + 1] = #r > 0 and r or nil
    end
    return t
end

local function string_to_table(string_data, level)
    if level == 3 then
        local res = {}
    end
end

local function convert_excel_to_table(sheet, shared)
    local sheet_data = get_sheet_data(sheet)
    local sst = get_sst(shared)
    local lua_table = sheet_data_to_table(sheet_data, sst)
    for i = 2, #lua_table, 1 do

    end
end

local function write_to_lua_file(toLua)
    local o = io.open(toLua, "w")
    o:write("local excel = {")
    for i = 2, #t, 1 do
        o:write("[" .. (i - 1) .. "] = {")
        for index, value in ipairs(t[i]) do
            if t[1][index] ~= "name" and t[1][index] ~= "desc" then
                o:write(t[1][index])
                o:write(" =\' ")
                o:write(value)
                o:write("' ,\n ")
            end
        end
        o:write("},")
    end
    o:write("}\n")
    o:write("return item_buff")
end


local function main()
    local JSON = require("utils.json2table")
    local XML = require("utils.xml2table")
    local f = io.open("config.json", "r")
    local config = JSON(f:read("a"))
    f:close()
    for key, value in pairs(config) do
        print(key, value)
    end

    local folder_path = config.xls_path
    local cmd = string.format('dir /b "%s"', folder_path) -- Windows系统使用dir命令，Linux/Unix系统使用ls命令
    local handle = io.popen(cmd)
    local path = {}
    if handle then
        local output = handle:read("l")
        while output do
            if string.match(output, "^.+%.xls$") then
                path[string.gsub(output, ".xls", "")] = folder_path .. "\\" .. output
            end
            output = handle:read("l")
        end
        handle:close()
    end

    local function time_to_number(time_string)
        local date_string = string.gsub(time_string, "(%d%d)/(%d%d)/(%d%d%d%d)  (%d%d):(%d%d) %aM", "%3%1%2%4%5")
        -- print(date_string)
        local time = tonumber(date_string)
        if string.find(time_string, "PM", 19) then
            time = time + 1200
        end
        return time
    end
    local xls_modify_time = {}

    for key, value in pairs(path) do
        cmd = string.format('dir /t:w "%s"', value)
        handle = io.popen(cmd)
        local output = handle:read("a")
        xls_modify_time[key] = time_to_number(string.match(output, "%d%d/%d%d/%d%d%d%d  %d%d:%d%d %aM"))
        handle:close()
    end

    local covert_to_xlsx = {}
    for key, value in pairs(xls_modify_time) do
        local target = config.temp .. "\\" .. key .. ".xlsx"
        f = io.open(target, "r")
        if f then
            f:close()
            cmd = string.format('dir /t:w "%s"', target)
            handle = io.popen(cmd)
            local output = handle:read("a")
            local xlsx_create_time = time_to_number(string.match(output, "%d%d/%d%d/%d%d%d%d  %d%d:%d%d %aM"))
            if value >= xlsx_create_time then
                covert_to_xlsx[config.xls_path .. "\\" .. key .. ".xls"] = target
            end
            handle:close()
        else
            covert_to_xlsx[config.xls_path .. "\\" .. key .. ".xls"] = target
        end
    end

    for key, value in pairs(covert_to_xlsx) do
        cmd = string.format(config.xls2xlsx_cmd, key, value)
        handle = io.popen(cmd)
        local output = handle:read("a")
        print("convert", key, "to", value, output)
        handle:close()
    end
    for key, value in pairs(covert_to_xlsx) do
        cmd = string.format(config.zip_cmd, value, config.temp)
        handle = io.popen(cmd)
        handle:close()
        f = io.open(config.temp .. "\\xl\\sharedStrings.xml", "r")
        local shared = f:read("a")
        f:close()
        -- local xml = XML(s)
        f = io.open(config.temp .. "\\xl\\worksheets\\sheet1.xml", "r")
        if not f then
            error(key .. " miss sheet1")
        end
        local sheet1 = f:read("a")
        f:close()
        convert_excel_to_table(XML(sheet1)[1], XML(sheet1)[shared], string.gsub(value, "xlsx$", "lua", 1))
    end
end
xpcall(main, function(a, b)
    print(a, b)
end)
