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
        "D:\\Closers.cocos\\resource\\data\\branches\\test\\excel\\buff_base.xls", no_config.temp .. "\\buff_base.xlsx") -- Windows系统使用dir命令，Linux/Unix系统使用ls命令
    local handle = io.popen(cmd)
    if handle then
        handle:close()
    else
        return
    end
    cmd = string.format(no_config.zip_cmd, no_config.temp .. "\\buff_base.xlsx", no_config.temp)
    handle = io.popen(cmd)
    if handle then
        handle:close()
    end
    f = io.open(no_config.temp .. "\\[Content_Types].xml", "r")
    s = ""
    if f then
        s = f:read("a")
        f:close()
        local xml = XML(s)
    else
        return
    end
else
    return
end



-- local f = io.open(, "r")
