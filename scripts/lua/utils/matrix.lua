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
function mt._newindex(matrix, k, v)
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
        __index = mt.__index
    })
    return matrix
end
