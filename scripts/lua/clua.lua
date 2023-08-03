do
    local p <close> = setmetatable({ 2 }, {
        __close = function()
            print("close")
        end
    })
    local t = { 1, 2, 3 }
    local a1, a2, a3 = pairs(t)
    for key, value in pairs(t) do
        print(key, value)
        local c, d, e, f = 1, 2, 3, 4
    end
    local x = 1
end
