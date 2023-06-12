local function quick_sort(t, lo, up, b)
    if lo < up then
        local p = lo + 1
        local vp = t[lo + 1]
        local k = lo
        local j = up
        for i = k, j do

        end


        quick_sort(t, lo, p, b)
        quick_sort(t, p, up, b)
    end
end

local a = { 3, 4, 1, 5, 6, 2, 6, 9, 0, 6, 4, 6 }
local b = {}
-- local a = { 4, 1, 2 }
debug.sethook(function(a, b)
    print(a, b)
end, "l")
xpcall(quick_sort, function(msg)
    print(msg)
end, a, 1, #a, b)

local t = {}
for index, value in ipairs(a) do
    t[index] = value
end

print(table.concat(t, ","))
