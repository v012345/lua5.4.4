local set = require "utils.set"
local matrix = require "utils.matrix"
local mt = {}

return function()
    local NFA = {
        alphabet = set(),
        states = set(),
        initial_states = set(),
        final_states = set(),
        transition_matrix = matrix(),
    }
end
