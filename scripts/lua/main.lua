local function main()
    local lfs = require "lfs"
    local xml = require("utils.csd2table")
    local csd = require("utils.table2csd")
    local root_path = "D:\\Closers.cocos\\resource\\ui\\branches\\dzogame_sea"

    ---comment
    ---@param lang string
    ---@return table<string,string>
    local function getFiles(lang)
        local m = {}
        local folder = string.format("%s\\%s\\cocosstudio\\ui", root_path, lang)
        for entry in lfs.dir(folder) do
            if entry ~= "." and entry ~= ".." then
                local filePath = folder .. "/" .. entry
                local fileAttributes = lfs.attributes(filePath)
                if fileAttributes.mode == "file" then
                    if string.match(string.lower(filePath), "^.+%.csd$") then
                        m[entry] = filePath
                    end
                end
            end
        end
        return m
    end

    local base = "en"
    local langs = { "zhcn", "id", "th", "vi" }
    if arg["extract"] then
        local csv = io.open("./trans.csv", "w") or error("can't open trans.csv")
        csv:write(string.format('"%s"', base), ",")
        for _, lang in ipairs(langs) do
            csv:write(string.format('"%s"', lang), ",")
        end
        csv:write('"csd","name","attribute","tag"\n')

        local function extract(csd_name, base_node, ...)
            local langs_node = table.pack(...)
            local ex_format = ',"%s","%s","%s","%s"\n'
            local function tocsv(attribute)
                csv:write('"', base_node.attributes[attribute], '"', ",")
                for _, lang_node in ipairs(langs_node) do
                    csv:write('"', lang_node.attributes[attribute], '"', ",")
                end
                csv:write(string.format(ex_format, csd_name, base_node.name, attribute, base_node.attributes["Tag"]))
            end

            if base_node.attributes["ButtonText"] then
                tocsv("ButtonText")
            end
            if base_node.attributes["LabelText"] then
                tocsv("LabelText")
            end
            if base_node.attributes["PlaceHolderText"] then
                tocsv("PlaceHolderText")
            end


            for key, child in ipairs(base_node.children) do
                local sub_langs_node = {}
                for i, lang_node in ipairs(langs_node) do
                    sub_langs_node[i] = lang_node.children[key]
                end
                extract(csd_name, child, table.unpack(sub_langs_node))
            end
        end
        local base_ui = getFiles(base)
        local langs_ui = {}
        for i, lang in ipairs(langs) do
            langs_ui[i] = getFiles(lang)
        end
        for csd_name, csd_path in pairs(base_ui) do
            local base_node = xml(csd_path)
            local langs_node = {}
            for i = 1, #langs_ui, 1 do
                langs_node[i] = xml(langs_ui[i][csd_name])
            end
            extract(csd_name, base_node, table.unpack(langs_node))
        end
        csv:close()
    elseif arg["replace"] then
        local csv = io.open("./trans.csv", "r") or error("can't open trans.csv")
    elseif arg["update"] then
    elseif arg["check"] then
        local base_ui = getFiles(base)
        print(">>> start checking >>>")

        for csd_name, csd_path in pairs(base_ui) do
            local name_map = {}
            ---comment
            ---@param node Node
            local function check(node)
                if node.attributes["LabelText"] or node.attributes["ButtonText"] or node.attributes["PlaceHolderText"] then
                    if name_map[node.name .. node.attributes["Tag"]] then
                        print(csd_name, node.name, "tag", node.attributes["Tag"], "is duplicated")
                    else
                        name_map[node.name .. node.attributes["Tag"]] = true
                    end
                end
                for _, child in ipairs(node.children) do
                    check(child)
                end
            end
            check(xml(csd_path))
        end
        print("<<< end checking <<<")
    end
    -- local a = coroutine.create(function() end)
    -- local b = coroutine.wrap(function(p1, p2, p3)
    --     print(p1, p2, p3)
    --     coroutine.yield()
    --     print("jjj")
    -- end)
    -- b(1, 2)
    -- b(1, 2)
    -- xpcall(function()
    --     local luafile = "./test-lua.lua"
    --     local bytecode = require "bytecode"
    --     local toJson = require "utils.table2json"
    --     local h5js = io.open("./vue/lua.json", "w") or error()
    --     local luaByteCode = luac(luafile)
    --     local function trans(cl)
    --         for _, value in pairs(cl.p) do
    --             trans(value)
    --         end
    --         cl.code = bytecode:show(cl.code)
    --     end
    --     trans(luaByteCode)
    --     h5js:write(toJson(luaByteCode))
    --     h5js:close()
    --     print("done")
    -- end, function(msg)
    --     print(msg)
    -- end)

    -- local map = {}
    -- local function traverseDirectory(path, root)
    --     for entry in lfs.dir(path) do
    --         if entry ~= "." and entry ~= ".." then
    --             local filePath = path .. "/" .. entry
    --             local fileAttributes = lfs.attributes(filePath)

    --             if fileAttributes.mode == "directory" then
    --                 traverseDirectory(filePath, root)
    --             elseif fileAttributes.mode == "file" then
    --                 map[#map + 1] = filePath
    --             end
    --         end
    --     end
    -- end
    -- traverseDirectory("D:\\Closers.resource\\handygame\\ko\\image", "D:\\Closers.resource\\handygame\\ko\\image")
    -- traverseDirectory("D:\\Closers.resource\\handygame\\ko\\piece", "D:\\Closers.resource\\handygame\\ko\\piece")
    -- -- traverseDirectory("D:\\Closers.resource\\dzogame_sea\\zhcn\\piece", "D:\\Closers.resource\\dzogame_sea\\zhcn\\piece")
    -- print(#map)
    for index, value in pairs(arg) do
        print(index, value)
    end

    local t = xml("Microsoft Edge.html")
    csd(t, "Microsoft Edge.xml")
    for key, value in pairs(t.children[1]) do
        print(key, value)
    end
    print()


    -- local f = io.open("xxx1.lua", "w")
    -- f:write("t = {")
    -- for index, value in pairs(output) do
    --     f:write(string.format('["%s"] = {', index))
    --     for key1, value1 in pairs(value) do
    --         f:write(string.format('["%s"] = "%s",', key1,value1))
    --     end
    --     f:write("},")
    -- end
    -- f:write("}")
    -- local md5 = require "utils.myMd5"
    -- local file = io.open("main.lua", "r") or error("can't read")
    -- local content = file:read("a")
    -- file:close()
    -- print(md5:sumhexa(content))
end


xpcall(main, function(msg)
    print(msg)
end)
