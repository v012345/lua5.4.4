xpcall(function(a, b)
    print(a, b)
    return a / nil
end, function(msg)
    print(msg)
end, 1, 0)
