local function quick_sort(t, lo, up)
    if lo < up then
        local p = (lo + up) // 2
        local vp = t[p]
        local k = lo
        local j = up
        print(lo, up)
        print(table.concat(t, ","))
        while true do
            while t[k] < vp do
                k = k + 1
            end
            while t[j] > vp do
                j = j - 1
            end
            if j <= k then
                p = j
                break
            else
                t[k], t[j] = t[j], t[k]
                if t[j] == t[k] and t[k] == vp then
                    j = j - 1
                end
            end
        end
        quick_sort(t, lo, p)
        quick_sort(t, p + 1, up)
    end
end

local a = { 3, 4, 1, 5, 6, 2, 6, 9, 0, 6, 4, 6 }
-- local a = { 4, 1, 2 }
-- debug.sethook(function(a, b)
--     print(a, b)
-- end, "l")
xpcall(quick_sort, function(msg)
    print(msg)
end, a, 1, #a)

local t = {}
for index, value in ipairs(a) do
    t[index] = value
end

print(table.concat(t, ","))
