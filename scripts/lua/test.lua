local function quick_sort(t, lo, up)
    if lo < up then
        local p = (lo + up) // 2

        local vp = t[p]
        local i = lo
        local j = up
        while true do
            while t[i] < vp do
                i = i + 1
            end
            while t[j] >= vp do
                j = j - 1
            end
            t[i], t[j] = t[j], t[i]
            if i >= j then
                p = i
                break
            end
        end
        quick_sort(t, lo, p)
        quick_sort(t, p, up)
    end
end

local a = { 3, 4, 1, 5, 6, 2, 6, 9, 0, 6, 4, 6 }
-- local a = { 4, 1, 2 }
debug.sethook(function(a, b)
    print(a, b)
end, "l")
xpcall(quick_sort, function(msg)
    print(msg)
end, a, 1, #a)

local t = {}
for index, value in ipairs(a) do
    t[index] = value
end

print(table.concat(t, ","))
