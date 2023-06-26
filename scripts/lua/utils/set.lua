---@class set
local mt = {}

function mt.generator(set)
    local a = 0
    local b = set.list
    return function()
        a = a + 1
        return b[a], a
    end
end

---@private
function mt.convert_to_table(eles)
    if (getmetatable(eles) or {}).__index == mt then
        return eles.list
    elseif type(eles) == "table" then
        return eles
    else
        return { eles }
    end
end

---@private
function mt.__len(set)
    return #set.list
end

function mt.contain(set, eles)
    for _, ele in ipairs(mt.convert_to_table(eles)) do
        if not set.pos[ele] then
            return false
        end
    end
    return true
end

---comment
---@param set set
---@param eles any
function mt.remove(set, eles)
    if set:contain(eles) then
        for _, ele in ipairs(mt.convert_to_table(eles)) do
            if set.pos[ele] then
                set.pos[ele] = false
            end
        end
        local list = {}
        for ele, pos in pairs(set.pos) do
            if pos then
                list[#list + 1] = ele
            end
        end
        local pos = {}
        for i, ele in pairs(list) do
            pos[ele] = i
        end
        set.list = list
        set.pos = pos
    end
end

function mt.insert(set, eles)
    for _, ele in ipairs(mt.convert_to_table(eles)) do
        if set.pos[ele] then
            return
        end
        set.list[#set.list + 1] = ele
        set.pos[ele] = #set.list
    end
end

---@private
function mt.new(set, list)
    for _, ele in ipairs(list) do
        if not set.pos[ele] then
            set.list[#set.list + 1] = ele
            set.pos[ele] = #set.list
        end
    end
end

---@private
function mt.__tostring(set)
    local t = {}
    for i, ele in ipairs(set.list) do
        t[#t + 1] = tostring(ele)
        t[#t + 1] = "\t"
        if i & 0x3 == 0 then
            t[#t + 1] = "\n"
        end
    end
    t[#t] = ""
    return table.concat(t)
end

---comment
---@private
---@param set1 set
---@param set2 set
---@return boolean
function mt.__eq(set1, set2)
    if set1 == set2 then
        return true
    else
        if #set1 == #set2 then
            return set1:contain(set1)
        end
        return false
    end
end

---comment
---@param list table|set|nil
---@return set
return function(list)
    ---@class set
    local set = {
        list = {},
        pos = {},
    }
    setmetatable(set, {
        __index = mt,
        __tostring = mt.__tostring,
        __len = mt.__len,
    })
    if list then
        set:new(mt.convert_to_table(list))
    end
    return set
end
