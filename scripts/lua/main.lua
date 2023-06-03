-- local lfs = require("lfs")
-- local json_parser = require("utils.json2table")
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
    "a", "b", "c", "d"
}
local frame = 0
local input_queue = {}
local logicCoroutine

local function logic(render_frame, birth_time, life_time)
    local function check_die()
        if os.clock() - birth_time >= life_time then
            render_frame, birth_time, life_time = coroutine.yield("快写吧~~")
        end
    end
    while true do
        check_die()
        if input_queue[current] then
            if input_queue[current] == "next" then
                current = current + 1
                render_frame, birth_time, life_time = coroutine.yield(map[(current&0x3)|1])
            end
        end
    end
end

logicCoroutine = coroutine.create(logic)
_Lua_functions = {
    test = require("test"),
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
        input_queue[positon] = "next"
    end
}
