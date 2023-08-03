do
    local p <close> = setmetatable({ 2 }, {
        __close = function()
            print("close")
        end
    })
    local t = { 1, 2, 3 }
    local a1, a2, a3 = pairs(t)
    for key, value, c1 in a1, a2, a3, p do
        print(key, value, c1)
    end
    local x = 1
end
