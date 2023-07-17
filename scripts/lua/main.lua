-- require "dot_parser.parser"
---@diagnostic disable-next-line
local a = 1
local b = not a
function main()
    -- local t = ChunkDump("./llex.lua")
    -- for key, value in pairs(t) do
    --     if key == "k" then
    --         for k, v in ipairs(value) do
    --             print(v)
    --         end
    --     else
    --         print(key, value)
    --     end
    -- end
    local get_png_size = require "utils.getPngSize"
    local lfs = require("lfs")
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
    local sea_root_path = "D:\\Closers.cocos\\resource\\ui\\branches\\dzogame_sea\\en\\cocosstudio\\image\\"
    traverseDirectory(sea_root_path, sea_root_path .. "/", "")
    local online_root_path =
    "D:\\Closers.cocos\\resource\\ui\\branches\\dzogame_sea\\zhcn\\cocosstudio\\image"
    local out = io.open("differ.txt", "w")

    for key, value in pairs(images_map) do
        if string.match(value, ".+%.png$") then
            -- print(get_png_size(string.format("%s/%s", sea_root_path, value)))
        else
            print(value)
        end

        -- local x = io.open(string.format("%s/%s", online_root_path, value), "r")
        -- if not x then
        --     print(value)
        -- else
        --     x:close()
        -- end
        -- local w1, h1 = get_png_size(string.format("%s/%s", sea_root_path, value))
        -- local w2, h2 = get_png_size(string.format("%s/%s", online_root_path, value))
        -- if w1 ~= w2 or h1 ~= h2 then
        --     out:write(value)
        --     out:write("\n")
        --     print(value)
        -- end
        -- local handle = io.popen(string.format("py ./imagesize.py \"%s\"", string.format("%s/%s", sea_root_path, value))) or
        --     error()
        -- local result1 = handle:read("*a")
        -- handle:close()
        -- handle = io.popen(string.format("py ./imagesize.py \"%s\"", string.format("%s/%s", online_root_path, value))) or
        --     error()
        -- local result2 = handle:read("*a")
        -- handle:close()
        -- if result2 ~= result1 then

        -- end
    end
    out:close()
    -- require "bm_excel_to_lua"
    -- local InputStream = require "utils.InputStream"
    -- local DotParser = require "dot_parser.DotParser"
    -- local FA = require "compiler.FA"
    -- local nfa = FA()
    -- DotParser("./dot/NDF.dot", nfa)
    -- local dfa = nfa:convertToDFA()
    -- dfa:toDot("./build/dot.dot")
    -- require "compiler.FA_Lable_Parser"
    -- print(nfa.FA_State_Matrix)

    ---@type InputStream
    -- local stream = InputStream("./dot/input.dot")
    -- while stream:next() do
    --     print(stream.current_char)
    -- end
    -- local state = require "compiler.FA_State"
    -- ---@type function, function
    -- local FA_State_Matrix, FA_State_Matrix_Entry = table.unpack((require "compiler.FA_State_Matrix"))
    -- ---@type FA_State_Matrix
    -- local m = FA_State_Matrix()

    -- m:addEntry(FA_State_Matrix_Entry(
    --     state(1, nil, 3, 3, 4, "6"), "a", 2
    -- ))
    -- m:addEntry(FA_State_Matrix_Entry(
    --     state(2), "a", 2
    -- ))
    -- m:addEntry(FA_State_Matrix_Entry(
    --     state(2), "bb", 3
    -- ))
    -- m:addEntry(FA_State_Matrix_Entry(
    --     state(3), "bcb", 3
    -- ))
    -- -- print(m)

    -- -- do
    -- --     return
    -- -- end
    -- require "clua"
    -- require "lparser"
    -- require "lzio"
    -- ---@type Zio
    -- local z = new(Zio)
    -- local firstchar = zgetc(z)
    -- luaY_parser(nil, z, new(Mbuffer), nil, "test.lua", firstchar)


    -- -- io.write(tostring(a))
    -- local dot2machine = require "utils.dot2machine"
    -- local file = io.open("./dot/NDF.dot", "r") or error("can't open NDF.dot")
    -- local content = file:read("a")
    -- file:close()
    -- local _, NFA = xpcall(dot2machine, function(msg)
    --     print(msg)
    -- end, content)
    -- -- -- NFA = NFA or {}
    -- file = io.open("./build/ast1.dot", "w") or error("can't open ast1.dot")
    -- file:write(tostring(NFA))
    -- file:close()
    -- local t = require "utils.nfa2dfa"
    -- xpcall(t.nfa2dfa, function(msg)
    --     print(msg)
    -- end, NFA)
    -- local minimizeDFA = require "utils.minimizeDFA"

    -- file = io.open("./build/ast2.dot", "w") or error("can't open ast2.dot")
    -- file:write(tostring(NFA))
    -- file:close()
    -- minimizeDFA(NFA)
    -- file = io.open("./build/ast3.dot", "w") or error("can't open ast3.dot")
    -- file:write(tostring(NFA))
    -- file:close()
end

xpcall(main, function(msg)
    print(msg)
end)



-- local file = io.open("./dot/input.dot", "r") or error("can't open input.dot")
-- local content = file:read("a")
-- file:close()
-- print(#content)
-- print(string.sub(content, 3, 3))

-- xpcall(NFA.output, function(msg)
--     print(msg)
-- end, NFA, "C:\\Users\\Meteor\\Desktop\\configs\\ast2.dot")
