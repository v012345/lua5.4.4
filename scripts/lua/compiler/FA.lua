---@type function, function
local FA_State_Matrix, FA_State_Matrix_Entry = table.unpack((require "compiler.FA_State_Matrix"))
local FA_State = require "compiler.FA_State"
local FA_Lable_Lex = require "compiler.FA_Lable_Lex"
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
    while this.FA_States:contain(r) do
        r = r + 1
    end
    this.FA_States:insert(r)
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
---@param entry FA_State_Matrix_Entry
---@return boolean
function mt.removeEntry(this, entry)
    local _, r = this.FA_State_Matrix:removeEntry(entry)
    return r
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

---comment
---@param this FA
---@return table<FA_State_Matrix_Entry>
function mt.getAllEntry(this)
    local r = {}
    for from_state, label_states in pairs(this.FA_State_Matrix) do
        for label, to_states in pairs(label_states) do
            for to_state in pairs(to_states) do
                r[#r + 1] = FA_State_Matrix_Entry(
                    FA_State(from_state),
                    label,
                    FA_State(to_state)
                )
            end
        end
    end
    return r
end

---@param this FA
---@param FA FA
---@param which_label string
function mt.insertFA(this, FA, which_label)
    local entry = FA_State_Matrix_Entry(
        FA.FA_Initial_States,
        which_label,
        FA.FA_Final_States
    )
    this:removeEntry(entry)
    local newEntries = FA:getAllEntry()
    for _, newEntry in ipairs(newEntries) do
        this:addEntry(newEntry)
    end
end

---comment
---@param this FA
---@param from_state FA_State
---@param to_state FA_State
function mt.closure(this, from_state, to_state)
    if #from_state == 1 and #to_state == 1 then
        this:addEntry(FA_State_Matrix_Entry(from_state, "", to_state))
    else
        error("only can closure one state to one state")
    end
end

---@param this FA
---@return FA
function mt.convertToDFA(this)
    local FA = (require "compiler.FA")()

    ---comment
    ---@param DFA FA
    ---@param NFA FA 获状态用
    ---@param from_state FA_State
    ---@param labelLex FA_Lable_Lex
    ---@param to_state FA_State
    local function unfold_label(DFA, NFA, from_state, labelLex, to_state)
        labelLex:next()
        while labelLex.current_char do
            if labelLex.current_char == "(" then
                local newLabelLex = labelLex:getNewLabel()
                local newState = NFA:getNewState()
                DFA:addEntry(FA_State_Matrix_Entry(
                    from_state,
                    labelLex.current_char,
                    newState
                ))
                unfold_label(DFA, NFA, from_state, newLabelLex, newState)
                if labelLex.current_char == "*" then
                    labelLex:next()
                    DFA:closure(from_state, newState)
                end
                unfold_label(DFA, NFA, newState, labelLex, to_state)
            elseif labelLex.current_char == "|" then
                unfold_label(DFA, NFA, from_state, labelLex, to_state)
            elseif labelLex.current_char == "*" then
                error("single * show")
            elseif labelLex.current_char == ")" then
                error("single ) show")
            elseif labelLex.current_char == "$" then
                local newState = NFA:getNewState()
                DFA:addEntry(FA_State_Matrix_Entry(
                    from_state,
                    labelLex:readAlias(),
                    newState
                ))
                unfold_label(DFA, NFA, newState, labelLex, to_state)
                if labelLex.current_char == "*" then
                    labelLex:next()
                    DFA:closure(from_state, newState)
                end
            else
                local newState = NFA:getNewState()
                DFA:addEntry(FA_State_Matrix_Entry(
                    from_state,
                    labelLex.current_char,
                    newState
                ))
                print(labelLex.current_char)
                unfold_label(DFA, NFA, newState, labelLex, to_state)
                if labelLex.current_char == "*" then
                    labelLex:next()
                    DFA:closure(from_state, newState)
                end
            end
        end
    end
    for from_state, label_states in pairs(this.FA_State_Matrix) do
        for label, to_states in pairs(label_states) do
            for to_state in pairs(to_states) do
                unfold_label(FA, this, FA_State(from_state), FA_Lable_Lex(label), FA_State(to_state))
            end
        end
    end
    return FA
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
            for label, to_states in pairs(label_states) do
                for to_state in pairs(to_states) do
                    t[#t + 1] = string.format(
                        "    %s -> %s [label = %s;];\n",
                        from_state,
                        to_state,
                        string.gsub(string.format("%q", label), "\\\n", "\\n")
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
    local FA = {
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
