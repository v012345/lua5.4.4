local FA_State = require "compiler.FA_State"

---@return table<string, FA_State>
local function label_state_map()
    ---@type table<string, FA_State>
    local label_state = {}
    setmetatable(label_state, {
        ---@param this table<string, FA_State>
        __tostring = function(this)
            local t = {}
            for label, to_state in pairs(this) do
                t[#t + 1] = string.format("%s -> %s\n", label, tostring(to_state))
            end
            return table.concat(t)
        end,
        ---@param this table<string, FA_State>
        ---@param k string
        ---@param v FA_State
        __newindex = function(this, k, v)
            if (type(k) == "string" and getmetatable(v) == "FA_State") then
                rawset(this, k, v)
            else
                error("key must be string and value must be FA_State")
            end
        end
    })
    return label_state
end


---@class FA_State_Matrix
---@field private convert_to_list function
---@field private __len function
---@field private __pairs function
---@field private __tostring function
---@field private __eq function
local mt = {}

---@param FA_State_Matrix FA_State_Matrix
---@param key any
---@return table<string, FA_State> | nil
function mt.__index(FA_State_Matrix, key)
    if mt[key] then
        return mt[key]
    end
    local from_state = FA_State(key)
    for state, label_state in pairs(FA_State_Matrix.states_label_state_table) do
        if state == from_state then
            return label_state
        end
    end
    return nil
end

function mt.__newindex()
    error("can't assign by quick access, please use `addEntry` function")
end

---comment
---@param FA_State_Matrix FA_State_Matrix
---@param FA_State_Matrix_Entry FA_State_Matrix_Entry
---@return FA_State_Matrix
function mt.addEntry(FA_State_Matrix, FA_State_Matrix_Entry)
    if getmetatable(FA_State_Matrix_Entry) ~= "FA_State_Matrix_Entry" then
        error("arg #2 must be a FA_State_Matrix_Entry")
    end
    local from_state = FA_State_Matrix_Entry.from_state
    for state, label_state in pairs(FA_State_Matrix.states_label_state_table) do
        if state == from_state then
            local to_state = label_state[FA_State_Matrix_Entry.by_label]
            if to_state then
                to_state:insert(FA_State_Matrix_Entry.to_state)
                return FA_State_Matrix
            else
                label_state[FA_State_Matrix_Entry.by_label] = FA_State(FA_State_Matrix_Entry.to_state)
            end
        end
    end
    local new_label_state = label_state_map()
    new_label_state[FA_State_Matrix_Entry.by_label] = FA_State(FA_State_Matrix_Entry.to_state)
    FA_State_Matrix.states_label_state_table[FA_State(FA_State_Matrix_Entry.from_state)] = new_label_state
    return FA_State_Matrix
end

---@param FA_State_Matrix FA_State_Matrix
---@return string
function mt.__tostring(FA_State_Matrix)
    local t = { ">>>>>>>>" }
    t[#t + 1] = "\n"
    for from_state, label_state in pairs(FA_State_Matrix.states_label_state_table) do
        local sub_t = {}
        t[#t + 1] = string.format("%s => \n", tostring(from_state))
        for label, to_state in pairs(label_state) do
            sub_t[#sub_t + 1] = string.format("    %s -> %s\n", label, tostring(to_state))
        end
        t[#t + 1] = table.concat(sub_t)
    end
    t[#t + 1] = "<<<<<<<<"
    return table.concat(t)
end

---@return table<function>
return {
    ---@return FA_State_Matrix
    function()
        ---@class FA_State_Matrix
        ---@field private states_label_state_table table<FA_State,table<string,FA_State>>
        local FA_State_Matrix = {
            states_label_state_table = {}
        }
        setmetatable(FA_State_Matrix, {
            __index = mt.__index,
            __newindex = mt.__newindex,
            __tostring = mt.__tostring,
            __len = mt.__len,
            __eq = mt.__eq,
            __pairs = mt.__pairs,
            __metatable = "FA_State_Matrix"
        })
        return FA_State_Matrix
    end,
    ---@return FA_State_Matrix_Entry
    function(from_state, by_label, to_state, ...)
        ---@class FA_State_Matrix_Entry
        ---@field from_state FA_State
        ---@field by_label string
        ---@field to_state FA_State
        if type(by_label) ~= "string" then
            error("entry arg #2 must be a string")
        end
        local FA_State_Matrix_Entry = {
            from_state = FA_State(from_state),
            by_label = by_label,
            to_state = FA_State({ to_state, ... }),
        }

        setmetatable(FA_State_Matrix_Entry, {
            __metatable = "FA_State_Matrix_Entry",
            ---@param t1 FA_State_Matrix_Entry
            ---@param t2 FA_State_Matrix_Entry
            __eq = function(t1, t2)
                if
                    t1.to_state == t2.to_state and
                    t1.by_label == t2.by_label and
                    t1.to_state == t2.to_state
                then
                    return true
                end
                return false
            end
        })
        return FA_State_Matrix_Entry
    end
}
