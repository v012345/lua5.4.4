local matrix = require "utils.matrix"
local set = require "utils.set"
local t = require "utils.nfa2dfa"

---comment
---@param PI matrix
---@param s set
---@param DNA NFA
---@return boolean
---@return string
local function check_can_divide(PI, s, DNA)
    for label in pairs(DNA.alphabet) do
        local Is = t.I(DNA.transition_matrix, s, label)
        local is_exist = false

        for pi in pairs(PI) do
            if pi:contain(Is) then
                is_exist = true
            end
        end
        if not is_exist then
            return true, label
        end
    end
    return false, ""
end
---comment
---@param DNA NFA
return function(DNA)
    local PI = matrix()

    local s2 = set(DNA.final_states)
    local s1 = set(DNA.states):remove(s2)
    PI[s1] = true
    PI[s2] = true
    print(check_can_divide(PI, s1, DNA))
    print("2222222")
    print(check_can_divide(PI, s2, DNA))
end
