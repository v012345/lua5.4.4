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

        local function getImagePath(node, path, node1, node2, node3, node4)
            -- print(node1)

            for key, value in pairs(node.children) do
                local node11 = node1.children[key]
                local node21 = node2.children[key]
                local node31 = node3.children[key]
                local node41 = node4.children[key]
                if value.attributes["ctype"] == "TextObjectData" then
                    if value.attributes["LabelText"] then
                        print(value.attributes["LabelText"])
                        f:write(string.format('"%s","%s","%s","%s","%s","%s","%s","%s"\n',
                            value.attributes["LabelText"],
                            node11.attributes["LabelText"],
                            node21.attributes["LabelText"],
                            node31.attributes["LabelText"],
                            node41.attributes["LabelText"],
                            path .. "/" .. value.name, "LabelText", value.attributes["Tag"]
                        ))
                    end
                end
                if value.attributes["ctype"] == "TextBMFontObjectData" then
                    if value.attributes["LabelText"] then
                        print(value.attributes["LabelText"])
                        f:write(string.format('"%s","%s","%s","%s","%s","%s","%s","%s"\n',
                            value.attributes["LabelText"],
                            node11.attributes["LabelText"],
                            node21.attributes["LabelText"],
                            node31.attributes["LabelText"],
                            node41.attributes["LabelText"],
                            path .. "/" .. value.name, "LabelText", value.attributes["Tag"]
                        ))
                    end
                end
                if value.attributes["ctype"] == "ButtonObjectData" then
                    if value.attributes["ButtonText"] then
                        print(value.attributes["ButtonText"])
                        f:write(string.format('"%s","%s","%s","%s","%s","%s","%s","%s"\n',
                            value.attributes["ButtonText"],
                            node11.attributes["ButtonText"],
                            node21.attributes["ButtonText"],
                            node31.attributes["ButtonText"],
                            node41.attributes["ButtonText"],
                            path .. "/" .. value.name, "ButtonText", value.attributes["Tag"]
                        ))
                    end
                end
                if value.attributes["ctype"] == "TextFieldObjectData" then
                    if value.attributes["PlaceHolderText"] then
                        print(value.attributes["PlaceHolderText"])
                        f:write(string.format('"%s","%s","%s","%s","%s","%s","%s","%s"\n',
                            value.attributes["PlaceHolderText"],
                            node11.attributes["PlaceHolderText"],
                            node21.attributes["PlaceHolderText"],
                            node31.attributes["PlaceHolderText"],
                            node41.attributes["PlaceHolderText"],
                            path .. "/" .. value.name, "PlaceHolderText", value.attributes["Tag"]
                        ))
                    end
                    if value.attributes["LabelText"] then
                        print(value.attributes["LabelText"])
                        f:write(string.format('"%s","%s","%s","%s","%s","%s","%s","%s"\n',
                            value.attributes["LabelText"],
                            node11.attributes["LabelText"],
                            node21.attributes["LabelText"],
                            node31.attributes["LabelText"],
                            node41.attributes["LabelText"],
                            path .. "/" .. value.name, "LabelText", value.attributes["Tag"]
                        ))
                    end
                end
                getImagePath(value, path .. "/" .. value.name, node11, node21, node31, node41)
            end
        end
        local base_ui = getFiles(base)
        for csd_name, csd_path in pairs(base_ui) do
            xml(csd_path)
        end
        -- local folder = string.format("%s\\%s\\cocosstudio\\ui", root_path, base)
        if string.match(string.lower(filePath), "^.+%.csd$") then
            local csd = io.open(filePath, "r") or error()
            local xml_s = csd:read("a")
            csd:close()
            local t = XML(xml_s)[1]


            csd = io.open(string.gsub(filePath, "\\en\\", "\\zhcn\\", 1), "r") or error()


            xml_s = csd:read("a")
            csd:close()
            local t1 = XML(xml_s)[1]

            csd = io.open(string.gsub(filePath, "\\en\\", "\\id\\", 1), "r") or error()
            xml_s = csd:read("a")
            csd:close()
            local t2 = XML(xml_s)[1]
            csd = io.open(string.gsub(filePath, "\\en\\", "\\th\\", 1), "r") or error()
            xml_s = csd:read("a")
            csd:close()
            local t3 = XML(xml_s)[1]
            csd = io.open(string.gsub(filePath, "\\en\\", "\\vi\\", 1), "r") or error()
            xml_s = csd:read("a")
            csd:close()
            local t4 = XML(xml_s)[1]
            getImagePath(t,
                string.gsub(entry,
                    "D:\\Closers.cocos\\resource\\ui\\branches\\dzogame_sea\\zhcn\\cocosstudio\\ui/", "",
                    1) ..
                "/" .. t.name,
                t1, t2, t3, t4
            )
            -- return
            -- map[#map + 1] = filePath
        end
        f:close()
    elseif arg["replace"] then
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
