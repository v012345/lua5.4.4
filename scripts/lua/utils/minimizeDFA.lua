local matrix = require "utils.matrix"
local set = require "utils.set"
local t = require "utils.nfa2dfa"

---comment
---@param PI matrix
---@param s set
---@param DNA NFA
---@return boolean
---@return string
---@return set
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
            return true, label, s
        end
    end
    return false, "", set()
end

local function divide(DNA, need_divide_set, PI, label)

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
    print(check_can_divide(PI, s2, DNA))
    local loop = true
    local divide_label = ""
    local need_divide = false
    local need_divide_set = set()
    while loop do
        for key, value in pairs(PI) do
            local need_divide_, label = check_can_divide(PI, key, DNA)
            if need_divide_ then
                divide_label = label
                need_divide = true
                need_divide_set = key
                break
            end
        end
        if need_divide then
            need_divide = false
        else
            loop = false
        end
    end
end
