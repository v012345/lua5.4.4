---@diagnostic disable-next-line
function main()
    local set = require "utils.set"
    local b = set({ "B" })
    local c = set(b)
    -- for value in a:generator() do
    --     print(value)
    -- end

    print(b == c)
    print(b)
    print(c)
end

xpcall(main, function(msg)
    print(msg)
end)
