-- require("bytedump")


-- local function a()
--     local b = 1
--     Bytedump:dump(GetOpCodes())
--     return function()
--         Bytedump:dump(GetOpCodes())
--         b = b + 1
--         return b
--     end
-- end
-- local c = a()
-- c()
-- require("utils.tools")

-- local xml = require("utils.xml2table")
-- local b = xml(s)
-- print(b.root[1].children[1].attributes.Name)
-- f = io.open("C:\\Users\\Meteor\\Desktop\\UiTutorialTips.csd", "r")
-- s = f and f:read("a") or ""
-- f:close()
-- local c = xml(s)
-- print(c.root[1].children[1].attributes.Name)
-- print(b.root[1].children[1].attributes.Name)
-- local c = xml("22222")
-- print(b.xml_string)
-- print(c.xml_string)
-- xml:parser(s)
local f = io.open("C:\\Users\\Meteor\\Desktop\\configs\\no_config.json", "r")
local s = ""
if f then
    s = f:read("a")
    f:close()
end

local JSON = require("utils.json2table")
local XML = require("utils.xml2table")
local config = JSON(s)
local csds = {}
if config then
    print()
    local folder_path = config.test_csd_path
    local cmd = string.format('dir /b "%s"', folder_path) -- Windows系统使用dir命令，Linux/Unix系统使用ls命令
    local handle = io.popen(cmd)

    local path = {}
    if handle then
        local output = handle:read("l")
        while output do
            if string.match(output, "^.+%.csd$") then
                path[#path + 1] = folder_path .. "\\" .. output
            end
            output = handle:read("l")
        end

        handle:close()
    end
    for index, value in ipairs(path) do
        f = io.open(value, "r")
        if f then
            csds[index] = XML(f:read("a"))
            print(index, "praser", value)
            f:close()
        end
    end
    local log = io.open(config.result_output_to, "w")
    if log then
        local function check(node, index)
            if node.attributes["Path"] and #node.attributes["Path"] < 5 then
                log:write(path[index])
                log:write("\n")
            end
            for key, value in pairs(node.children) do
                print(index)
                check(value, index)
            end
        end
        for index, value in ipairs(csds) do
            check(value[1], index)
        end
        log:close()
    end
end

-- print(output)
-- --
-- -- local t = {}
-- -- if f then
-- --     local x = f:read("n")

-- --     while x do
-- --         if t[x] then
-- --             t[x] = t[x] + 1
-- --         else
-- --             t[x] = 1
-- --         end
-- --         x = f:read("n")
-- --     end
-- -- end
-- -- for key, value in pairs(t) do
-- --     print(key, value)
-- -- end



-- -- local JSON = require("utils.read_json")
-- -- -- -- print(type(JSON))
-- -- local s = os.clock()
-- -- JSON:parser("C:\\Users\\Meteor\\Desktop\\New Text Document.json")

-- -- JSON:dump("C:\\Users\\Meteor\\Desktop\\o.txt")
-- -- local e = os.clock()
-- -- print(e - s)


-- -- local a
-- -- while a do
-- --     print(a)
-- -- end

-- -- local r2 = JSON("C:\\Users\\Meteor\\Desktop\\New Text Document.json")
-- -- print(r1() == r2())
-- -- print(r1)
-- -- print(type(r1))
-- -- print(type(r2))
-- -- if r then
-- --
-- -- end
-- Bytedump:dump(GetOpCodes())





-- -- local function c()
-- --     local counter = 1
-- --     return function()
-- --         counter = counter + 1
-- --         return counter
-- --     end
-- -- end

-- -- local counter1 = c()
-- -- local counter2 = c()
-- -- print(counter1())
-- -- print(counter1())
-- -- print(counter2())
-- -- print(counter2())
-- -- local tools = { [1] = 2, [3] = 2, a = 2 }
-- -- local a = #tools
