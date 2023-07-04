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
---@return FA_State
function mt.getNewState(this)
    if #this.FA_States <= 0 then
        for from_state, label_states in pairs(this.FA_State_Matrix) do
            this.FA_States:insert(from_state)
            for _, to_states in pairs(label_states) do
                this.FA_States:insert(to_states)
            end
        end
    end
    local r = #this.FA_States
    while not this.FA_States:contain(r) do
        r = r + 1
    end

    return FA_State(r)
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

---@param this FA
function mt.toDot(this, file_path)
    local t = {}
    t[#t + 1] = "digraph " .. this.FA_Name .. " {\n"
    t[#t + 1] = "    rankdir = LR;\n"
    t[#t + 1] = "    node [shape = doublecircle;];\n"
    for k in pairs(this.FA_Initial_States) do
        if this.FA_Final_States:contain(k) then
            t[#t + 1] = string.format("    %s [color = yellow;];\n", k)
        else
            t[#t + 1] = string.format("    %s [color = green;];\n", k)
        end
    end
    for k in pairs(this.FA_Final_States) do
        if not this.FA_Initial_States:contain(k) then
            t[#t + 1] = string.format("    %s [color = red;];\n", k)
        end
    end
    t[#t + 1] = string.format("    node [shape = circle;];\n")
    for from_states, label_states in pairs(this.FA_State_Matrix) do
        for from_state in pairs(from_states) do
            for lable, to_states in pairs(label_states) do
                for to_state in pairs(to_states) do
                    t[#t + 1] = string.format(
                        "    %s -> %s [label = %s;];\n",
                        from_state,
                        to_state,
                        string.gsub(string.format("%q", lable), "\\\n", "\\n")
                    )
                end
            end
        end
    end
    t[#t + 1] = "}\n"
    local file = io.open(file_path, "w") or error("can't open " .. file_path)
    file:write(table.concat(t))
    file:close()
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
