function test1(i)
    return i + 1
end

function test2(i)
    test1(i)
    return i + 1
end

function test3(i)
    test2(i)
    return i + 1
end

function test4(i)
    test3(i)
    return i + 1
end

test4(1)
-- xpcall(test4, function(msg)
--     print(msg)
-- end, 1)
