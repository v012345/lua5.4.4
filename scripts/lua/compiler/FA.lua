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
