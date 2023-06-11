debug.sethook(function(a, b)
    print(a, b)
end, "l")

local function partition(t, l, h, p)
    while l < h do
        while t[l] < p do
            l = l + 1
        end
        while t[h] > p do
            h = h - 1
        end
        t[l], t[h] = t[h], t[l]
    end
    return l
end

local function quick_sort(t, l, h)
    if l < h then
        local i = math.random(l, h)
        local j = partition(t, l, h, i)
        quick_sort(t, l, j)
        quick_sort(t, j, h)
    end
end

local a = { 3, 4, 1, 5, 6, 2, 6, 9, 0, 6, 4, 6 }

quick_sort(a, 1, #a)

local t = {}
for index, value in ipairs(a) do
    t[index] = value
end

print(table.concat(t, ","))
