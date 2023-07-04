---@type function, function
local FA_State_Matrix, FA_State_Matrix_Entry = table.unpack((require "compiler.FA_State_Matrix"))
local FA_State = require "compiler.FA_State"
---@class FA
local mt = {}

---comment
---@param FA FA
---@param dot_file_path string
function mt.load(FA, dot_file_path)

end

---@param this FA
---@param name string
function mt.setName(this, name)
    this.FA_Name = name
end

---comment
---@param this FA
---@param entry FA_State_Matrix_Entry
function mt.addEntry(this, entry)
    this.FA_State_Matrix:addEntry(entry)
end

---comment
---@param this FA
---@param states FA_State
function mt.addInitialStates(this, states)
    this.FA_Initial_States:insert(states)
end

---comment
---@param this FA
---@param states FA_State
function mt.addFinalStates(this, states)
    this.FA_Final_States:insert(states)
end

return function()
    ---@class FA
    ---@field FA_Alphabet table<string, true>
    ---@field FA_Initial_States FA_State
    ---@field FA_Final_States FA_State
    ---@field FA_States FA_State
    ---@field FA_State_Matrix FA_State_Matrix
    FA = {
        FA_Name = "no_name",
        FA_Alphabet = {},
        FA_Initial_States = FA_State(),
        FA_Final_States = FA_State(),
        FA_States = FA_State(),
        FA_State_Matrix = FA_State_Matrix()
    }
    setmetatable(FA, {
        __index = mt,
        __metatable = "FA"
    })
    return FA
end
