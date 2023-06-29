local matrix = require "utils.matrix"
local set = require "utils.set"
local function d()

end
---comment
---@param DNA NFA
return function(DNA)
    local PI = matrix()

    local s2 = set(DNA.final_states)
    local s1 = set(DNA.states):remove(s2)
    print(s1)
    print(s2)
    PI[s1] = true
    PI[s2] = true
end
