local set = require "utils.set"
---@class matrix
local mt = {}

---comment
---@private
---@param matrix matrix
---@param key any
---@return unknown
function mt.__index(matrix, key)
    if getmetatable(key) == "set" then
        for k, v in pairs(matrix.set_key_table) do
            if key == k then
                return v
            end
        end
        return nil
    else
        return matrix.normal_key_table[key]
    end
end

---comment
---@param matrix matrix
---@param k any
---@param v any
function mt.__newindex(matrix, k, v)
    if getmetatable(k) == "set" then
        for key, _ in pairs(matrix.set_key_table) do
            if k == key then
                matrix.set_key_table[key] = v
                return
            end
        end
        matrix.set_key_table[set(k)] = v
    else
        matrix.normal_key_table[k] = v
    end
end

function mt.__pairs(matrix)
    local use_normal_key_table = true
    return function(_, key)
        if use_normal_key_table then
            local k, v = next(matrix.normal_key_table, key)
            if k then
                return k, v
            else
                use_normal_key_table = false
                return next(matrix.set_key_table, nil)
            end
        else
            return next(matrix.set_key_table, key)
        end
    end
end

---comment
---@return matrix
return function()
    ---@class matrix
    local matrix = {
        normal_key_table = {},
        set_key_table = {},
    }
    setmetatable(matrix, {
        __metatable = "matrix",
        __newindex = mt.__newindex,
        __index = mt.__index,
        __pairs = mt.__pairs,
    })
    return matrix
end
