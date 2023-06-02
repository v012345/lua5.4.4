-- local frame = 0
-- local input = {}
-- local renderCoroutine
-- local logicCoroutine
-- local function render()
--     -- 渲染逻辑
--     while true do
--         os.execute("cls")
--         print(os.clock())
--         -- os.clock()
--         coroutine.yield()
--     end
-- end

-- local function logic()
--     -- 逻辑计算
--     frame = frame + 1
-- end

-- local function gameLoop()
--     renderCoroutine = coroutine.create(render)
--     logicCoroutine = coroutine.create(logic)
--     while true do
--         -- 渲染

--         coroutine.resume(renderCoroutine)

--         -- 逻辑计算

--         coroutine.resume(logicCoroutine)

--         -- 等待一帧的时间
--     end
-- end
-- xpcall(gameLoop, function(e)
--     print(e)
-- end)

_Lua_functions = {
    test = require("test"),
    print_time = function ()
        print(os.clock())
    end
}
