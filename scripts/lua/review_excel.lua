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

local function convert_excel_to_table(sheet, shared)
    -- print(sheet.children[1].attributes.ref)
    local sheet_data = get_sheet_data(sheet)
    local sst = get_sst(shared)
    -- for key, value in pairs(sst) do
    --     print(key, value)
    -- end
    -- xpcall(sheet_data_to_table, function(a, b)
    --     print(a, b)
    -- end, sheet_data, sst)
    local t = sheet_data_to_table(sheet_data, sst)
    -- print(t)
    -- for key, value in pairs(t) do
    --     print(table.concat(value, "\t"))
    -- end
    local o = io.open("C:\\Users\\Meteor\\Desktop\\configs\\item_buff.lua", "w")
    o:write("local item_buff = {")
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
local f = io.open("C:\\Users\\Meteor\\Desktop\\configs\\no_config.json", "r")
local s = ""
if f then
    s = f:read("a")
    f:close()
else
    return
end
local JSON = require("utils.json2table")
local XML = require("utils.xml2table")
local no_config = JSON(s)
if no_config then
    local cmd = string.format(no_config.xls2xlsx_cmd,
        "D:\\Closers.cocos\\resource\\data\\branches\\test\\excel\\item_buff.xls", no_config.temp .. "\\item_buff.xlsx") -- Windows系统使用dir命令，Linux/Unix系统使用ls命令
    local handle = io.popen(cmd)
    if handle then
        handle:close()
    else
        return
    end
    cmd = string.format(no_config.zip_cmd, no_config.temp .. "\\item_buff.xlsx", no_config.temp)
    handle = io.popen(cmd)
    if handle then
        handle:close()
    end
    f = io.open(no_config.temp .. "\\xl\\sharedStrings.xml", "r")
    s = ""
    if f then
        s = f:read("a")
        f:close()
        local xml = XML(s)
        f = io.open(no_config.temp .. "\\xl\\worksheets\\sheet1.xml", "r")
        s = f:read("a")
        f:close()
        convert_excel_to_table(XML(s)[1], xml[1])
        -- print(xml[1].children[4].children[1].content)
    else
        return
    end
else
    return
end




-- local f = io.open(, "r")
