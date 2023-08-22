local function main()
    local lfs = require "lfs"
    local xml = require("utils.csd2table")
    local csd = require("utils.table2csd")
    local root_path = "D:\\Closers.cocos\\resource\\ui\\branches\\dzogame_sea"
    local function getSha1(path)
        local windows_path = string.gsub(path, "/", "\\")
        local cmd = string.format('certutil -hashfile "%s"', windows_path)
        local result = io.popen(cmd) or error("can't run " .. cmd)
        local _, r = result:read("l"), result:read("l")
        result:close()
        return r
    end

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

    local base = "zhcn"
    local langs = { "en", "id", "th", "vi" }

    -- local base_ui = getFiles(base)
    -- for key, value in pairs(base_ui) do
    --     print(key, getSha1(value), lfs.attributes(value, "modification"))
    -- end
    local function update()
        local json = require "utils.table2json"
        local base_ui = getFiles(base)
        local t = {}
        for csd_name, csd_path in pairs(base_ui) do
            t[csd_name] = {
                modification = lfs.attributes(csd_path, "modification"),
                sha1 = getSha1(csd_path)
            }
        end
        local json_string = json(t)
        local json_file = io.open("build/csd.json", "w") or error("can't open build/csd.json")
        json_file:write(json_string)
        json_file:close()
    end


    if arg["extract"] then
        print(">>> start extracting >>>")
        local csv = io.open("./trans.csv", "w") or error("can't open trans.csv")
        csv:write(string.format('"%s"', base), ",")
        for _, lang in ipairs(langs) do
            csv:write(string.format('"%s"', lang), ",")
        end
        csv:write('"csd","name","attribute","tag"\n')

        local function extract(csd_name, base_node, ...)
            local langs_node = table.pack(...)
            local ex_format = '"%s","%s","%s","%s"\n'
            local function tocsv(attribute)
                csv:write('"', base_node.attributes[attribute], '"', ",")
                for _, lang_node in ipairs(langs_node) do
                    csv:write('"', lang_node.attributes[attribute], '"', ",")
                end
                csv:write(string.format(ex_format, csd_name, base_node.attributes["Name"], attribute,
                    base_node.attributes["Tag"]))
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
        local index = 1
        for csd_name, csd_path in pairs(base_ui) do
            print(index, csd_name)
            index = index + 1
            local base_node = xml(csd_path)
            local langs_node = {}
            for i = 1, #langs_ui, 1 do
                langs_node[i] = xml(langs_ui[i][csd_name])
            end
            extract(csd_name, base_node, table.unpack(langs_node))
        end
        print("<<< end extracting <<<")
        csv:close()
    elseif arg["replace"] then
        local json = require "utils.json2table"
        local json_file = io.open("build/csd.json", "r") or error("can't open build/csd.json")
        local csd_json = json(json_file:read("a")) or {}
        json_file:close()
        local csv = require "utils.csv2table"
        local raw_trans = csv("./trans.csv")
        local trans = {}
        for i = 2, #raw_trans, 1 do
            local row = raw_trans[i]
            local file = row[6]
            trans[file] = trans[file] or {}
            local sub_trans = trans[file]
            sub_trans[row[1]] = sub_trans[row[1]] or {}
            local langs_trans = sub_trans[row[1]]
            for index, _ in ipairs(langs) do
                langs_trans[index] = row[index + 1]
            end
        end
        local function replace(csd_name, base_node, ...)
            local langs_node = table.pack(...)
            local file_trans = trans[csd_name]
            local attributes = { "ButtonText", "LabelText", "PlaceHolderText" }
            for _, attribute in ipairs(attributes) do
                if base_node.attributes[attribute] then
                    local sub_file_trans = file_trans[base_node.attributes[attribute]] or
                        error(csd_name .. " has new text")

                    for index, lang_node in ipairs(langs_node) do
                        lang_node.attributes[attribute] = sub_file_trans[index]
                    end
                end
            end
            for key, child in ipairs(base_node.children) do
                local sub_langs_node = {}
                for i, lang_node in ipairs(langs_node) do
                    sub_langs_node[i] = lang_node.children[key]
                end
                replace(csd_name, child, table.unpack(sub_langs_node))
            end
        end
        local base_ui = getFiles(base)
        local langs_ui = {}
        for i, lang in ipairs(langs) do
            langs_ui[i] = getFiles(lang)
        end
        local index = 1

        for csd_name, csd_path in pairs(base_ui) do
            if csd_json[csd_name].modification < lfs.attributes(csd_path, "modification") and
                csd_json[csd_name].sha1 ~= getSha1(csd_path)
            then
                print(index, csd_name)
                index = index + 1
                local base_node = xml(csd_path)
                local langs_node = {}
                for i = 1, #langs_ui, 1 do
                    langs_node[i] = xml(langs_ui[i][csd_name])
                end
                replace(csd_name, base_node, table.unpack(langs_node))
                for indx, lang_node in ipairs(langs_node) do
                    csd(lang_node, string.format("%s\\%s\\cocosstudio\\ui\\%s", root_path, langs[indx], csd_name))
                end
            end
        end
        update()
    elseif arg["update"] then
        update()
    elseif arg["check"] then
        local base_ui = getFiles(base)
        print(">>> start checking >>>")

        for csd_name, csd_path in pairs(base_ui) do
            local name_map = {}
            ---comment
            ---@param node Node
            local function check(node)
                if node.attributes["LabelText"] or node.attributes["ButtonText"] or node.attributes["PlaceHolderText"] then
                    if name_map[node.attributes["Name"] .. node.attributes["Tag"]] then
                        print(csd_name, node.attributes["Name"], "tag", node.attributes["Tag"], "is duplicated")
                    else
                        name_map[node.attributes["Name"] .. node.attributes["Tag"]] = true
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
end


xpcall(main, function(msg)
    print(msg)
end)
