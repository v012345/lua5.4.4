local test = {}
function test:run()
    local function my_coroutine()
        print("coroutine start")
        coroutine.yield()
        print("coroutine resume")
    end

    local co = coroutine.create(my_coroutine)

    print("main start")
    coroutine.resume(co)
    print("main resume")
end

return test
