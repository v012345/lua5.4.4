local set = require "utils.set"
local matrix = require "utils.matrix"

---@class NFA
local mt = {}

---comment
---@param NFA NFA
---@param char any
function mt.add_char(NFA, char)
    NFA.alphabet:insert(char)
end

---comment
---@param NFA NFA
---@param char any
function mt.remove_char(NFA, char)
    NFA.alphabet:remove(char)
end

---comment
---@param NFA NFA
---@param states any
function mt.add_states(NFA, states)
    NFA.states:insert(states)
end

---comment
---@param NFA NFA
---@param states any
function mt.remove_states(NFA, states)
    NFA.states:remove(states)
    NFA.initial_states:remove(states)
    NFA.final_states:remove(states)
end

---comment
---@param NFA NFA
---@param states any
function mt.add_initial_states(NFA, states)
    NFA.initial_states:insert(states)
    NFA.states:insert(states)
end

---comment
---@param NFA NFA
---@param states any
function mt.remove_initial_states(NFA, states)
    NFA.initial_states:remove(states)
end

---comment
---@param NFA NFA
---@param states any
function mt.add_final_states(NFA, states)
    NFA.final_states:insert(states)
    NFA.states:insert(states)
end

---comment
---@param NFA NFA
---@param states any
function mt.remove_final_states(NFA, states)
    NFA.final_states:remove(states)
end

---comment
---@param NFA NFA
function mt.__tostring(NFA)
    local t = {}
    t[#t + 1] = "digraph nfa {\n"
    t[#t + 1] = "    rankdir = LR;\n"
    t[#t + 1] = "    size = \"8,5\";\n"
    t[#t + 1] = "    node [shape = doublecircle;];\n"
    for k in pairs(NFA.initial_states) do
        t[#t + 1] = string.format("    %s [color = green;];\n", k)
    end
    for k in pairs(NFA.final_states) do
        t[#t + 1] = string.format("    %s [color = red;];\n", k)
    end
    t[#t + 1] = string.format("    node [shape = circle;];\n")
    for from_state, row in pairs(NFA.transition_matrix) do
        for lable, to_states in pairs(row) do
            for to_state in pairs(to_states) do
                t[#t + 1] = string.format(
                    "    %s -> %s [label = %s;];\n",
                    from_state,
                    to_state,
                    string.format("%q", lable)
                )
            end
        end
    end
    t[#t + 1] = "}\n"
    return table.concat(t)
end

return function()
    ---@class NFA
    local NFA = {
        alphabet = set(),
        ---@type matrix transition_matrix[string][string] = set(states)
        transition_matrix = matrix(),
        states = set(),
        initial_states = set(),
        final_states = set(),
    }
    setmetatable(NFA, {
        __index = mt,
        __tostring = mt.__tostring,
    })
    return NFA
end
