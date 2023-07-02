---@class FA_State
---@field private convert_to_list function
---@field private __len function
---@field private __pairs function
---@field private __tostring function
---@field private __eq function
local mt = {}

---@param FA_State FA_State
---@return function
function mt.__pairs(FA_State)
    local a = 0
    local b = FA_State.list
    return function()
        a = a + 1
        return b[a]
    end
end

---@param FA_State FA_State
---@return integer
function mt.__len(FA_State)
    return #FA_State.list
end

---@param FA_State FA_State
---@param ... unknown
---@return boolean
function mt.contain(FA_State, ...)
    for _, ele in ipairs(mt.convert_to_list(...)) do
        if not FA_State.pos[ele] then
            return false
        end
    end
    return true
end

---@param FA_State FA_State
---@param ... unknown
function mt.remove(FA_State, ...)
    for _, ele in ipairs(mt.convert_to_list(...)) do
        if FA_State.pos[ele] then
            FA_State.pos[ele] = false
        end
    end
    local list = {}
    for ele, pos in pairs(FA_State.pos) do
        if pos then
            list[#list + 1] = ele
        end
    end
    local pos = {}
    for i, ele in pairs(list) do
        pos[ele] = i
    end
    FA_State.list = list
    FA_State.pos = pos

    return FA_State
end

---@param FA_State FA_State
---@param ... unknown
---@return FA_State
function mt.insert(FA_State, ...)
    for _, ele in ipairs(mt.convert_to_list(...)) do
        if not FA_State.pos[ele] then
            FA_State.list[#FA_State.list + 1] = ele
            FA_State.pos[ele] = #FA_State.list
        end
    end
    return FA_State
end

---@param FA_State FA_State
---@return string
function mt.__tostring(FA_State)
    local t = { "state = {" }
    t[#t + 1] = " "
    for _, ele in ipairs(FA_State.list) do
        t[#t + 1] = ele
        t[#t + 1] = ", "
    end
    if #t == 2 then
        t[#t] = "}"
    else
        t[#t] = " }"
    end
    return table.concat(t)
end

---comment
---@param FA_State1 FA_State
---@param FA_State2 FA_State
---@return boolean
function mt.__eq(FA_State1, FA_State2)
    if #FA_State1 == #FA_State2 then
        return FA_State1:contain(FA_State2)
    end
    return false
end

---@param ... unknown
---@return table
function mt.convert_to_list(...)
    local list = {}
    local input = { ... }
    local function unpack(t, l)
        local arg_type = type(t)
        if arg_type == "string" then
            l[# l + 1] = t
        elseif arg_type == "number" and math.type(t) == "integer" then
            l[# l + 1] = tostring(t)
        elseif arg_type == "table" then
            if getmetatable(t) == "FA_State" then
                for v in pairs(t) do
                    l[# l + 1] = v
                end
            else
                for _, v in pairs(t) do
                    unpack(v, l)
                end
            end
        else
            error("invalid data to construct a FA_State", 1)
        end
    end
    unpack(input, list)
    return list
end

---@param ... unknown
---@return FA_State
return function(...)
    ---@class FA_State
    ---@field private list table
    ---@field private pos table
    local FA_State = {
        list = {},
        pos = {},
    }
    setmetatable(FA_State, {
        __index = mt,
        __tostring = mt.__tostring,
        __len = mt.__len,
        __eq = mt.__eq,
        __pairs = mt.__pairs,
        __metatable = "FA_State"
    })
    for _, ele in ipairs(mt.convert_to_list(...)) do
        if not FA_State.pos[ele] then
            FA_State.list[#FA_State.list + 1] = ele
            FA_State.pos[ele] = #FA_State.list
        end
    end
    return FA_State
end
