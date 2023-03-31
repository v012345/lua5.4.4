debug.sethook(coroutine.running(), function()
    print(1)
end, "l")
