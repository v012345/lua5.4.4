local function Node()
    return {
        children = {},
        from = 1,
        to = 2,
        is_closure = false
    }
end
local tree = {}
local label = "|abc*|(a|b)*|(abc)d"

local function catchSiblings(label)
    local level = 0
    local r = {}
    local b = {}
    for i = 1, #label do
        local char = string.sub(label, i, i)
        if char == "(" then level = level + 1 end
        if char == ")" then level = level - 1 end
        if char == "|" and level == 0 then
            r[#r + 1] = table.concat(b)
            b = {}
        else
            b[#b + 1] = char
        end
    end
    r[#r + 1] = table.concat(b)
    return r
end

local function catchChildren(label)
    local level = 0
    local r = {}
    local b = {}
    local i = 1
    if label == "" then
        return { "" }
    end
    while true do
        local char = string.sub(label, i, i)
        if char == "" then
            break
        end
        local next_char = string.sub(label, i + 1, i + 1)
        if char == "(" then level = level + 1 end
        if char == ")" then level = level - 1 end
        if
            level > 0
        then
            b[#b + 1] = char
        else
            if #b > 0 then

            end
        end
        i = i + 1
    end

    r[#r + 1] = table.concat(b)
    return r
end




local function parser(label)
    local siblings = catchSiblings(label)
    if #siblings > 1 then
        for _, sibling in ipairs(siblings) do
            parser(sibling)
        end
    else
        local children = catchChildren(siblings[1])
        if #children > 1 then
            for _, child in ipairs(children) do
                parser(child)
            end
        else
            print(children[1])
        end
    end
end
parser(label)
