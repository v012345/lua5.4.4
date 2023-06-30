-- local lfs = require("lfs")
local json_parser = require("utils.json2table")
local read_file_content = function(file_path)
    local file = io.open(file_path, "r") or error("can't read config")
    local content = file:read("a")
    file:close()
    return content
end
-- local xml_parser = require("utils.xml2table")
-- local file = io.open("config.json", "r") or error("can't read config")
-- local config = json_parser(file:read("a")) or {}
-- file:close()
-- local images_map = {}

-- local function traverseDirectory(path, root, prefix)
--     local map = images_map
--     for entry in lfs.dir(path) do
--         if entry ~= "." and entry ~= ".." then
--             local filePath = path .. "/" .. entry
--             local fileAttributes = lfs.attributes(filePath)

--             if fileAttributes.mode == "directory" then
--                 traverseDirectory(filePath, root, prefix)
--             elseif fileAttributes.mode == "file" then
--                 map[entry] = string.gsub(filePath, root, prefix)
--             end
--         end
--     end
-- end
local current = 1
local positon = 0
local map = {
    "あ", "い", "う", "え", "お", "か", "き", "く", "け", "こ", "さ", "し", "す", "せ", "そ", "た", "ち",
    "つ", "て", "と", "な", "に", "ぬ", "ね", "の", "は", "ひ", "ふ", "へ", "ほ", "ま", "み", "む", "め",
    "も", "や", "ゆ", "よ", "ら", "り", "る", "れ", "ろ", "わ", "を", "ん"
}
local frame = 0
local input_queue = {}
local logicCoroutine
local words = json_parser(read_file_content("./words.json")) or {}
local Show_State = {}

local function logic(render_frame, birth_time, life_time)
    local map_index = 1
    local function check_die()
        if os.clock() - birth_time >= life_time then
            render_frame, birth_time, life_time = coroutine.yield("快写吧~~")
        end
    end
    while true do
        check_die()
        if input_queue[current] and input_queue[current] == "next" then
            current = current + 1
            render_frame, birth_time, life_time = coroutine.yield(words[map_index])
            map_index = math.random(1, #words)
        else
            render_frame, birth_time, life_time = coroutine.yield(words[map_index])
        end
    end
end

logicCoroutine = coroutine.create(logic)
_Lua_functions = {
    -- test = require("test"),
    print_time = function()
        print(os.clock())
    end,
    logic = function(render_frame, input, delta)
        local delta = 0.01
        local _, r = coroutine.resume(logicCoroutine, render_frame, os.clock(), delta)
        return r
    end,
    input = function(render_frame, input, delta)
        positon = positon + 1
        print("next")
        input_queue[positon] = "next"
    end
}
