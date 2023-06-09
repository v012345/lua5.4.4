local function partition(t, l, h, p)
    while l < h do

    end
end

local function quick_sort(t, l, h)
    if l < h then
        local i = math.random(l, h)
        partition(t, l, h, t[i])
    end
end
