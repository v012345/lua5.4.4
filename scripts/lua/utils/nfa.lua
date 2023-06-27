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
    NFA.states:remove(states)
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
    NFA.states:remove(states)
end

return function()
    ---@class NFA
    local NFA = {
        alphabet = set(),
        transition_matrix = matrix(),
        states = set(),
        initial_states = set(),
        final_states = set(),
    }
    setmetatable(NFA, {
        __index = mt
    })
    return NFA
end
