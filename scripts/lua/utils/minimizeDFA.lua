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

---comment
---@param DNA NFA
---@param need_divide_set set
---@param PI matrix
---@param label string
local function divide(DNA, need_divide_set, PI, label)
    local target_set = nil
    local another_set = set()
    for state in pairs(need_divide_set) do
        local tms = DNA.transition_matrix[state]
        if tms then
            local ts = tms[label]
            if #ts > 1 then
                error("set len greater one")
            end
            if not need_divide_set:contain(ts) then
                if target_set then
                    if target_set:contain(ts) then
                        another_set:insert(state)
                    end
                else
                    -- print(state, label, ts)
                    for v in pairs(PI) do
                        if v:contain(ts) and v ~= need_divide_set then
                            target_set = v
                            another_set:insert(state)
                            break
                        end
                    end
                end
            end
        end
    end
    if target_set then
        PI[need_divide_set] = nil

        local set1 = need_divide_set:remove(another_set)
        PI[set1] = true
        PI[another_set] = true
    end
end

---comment
---@param DNA NFA
return function(DNA)
    local PI = matrix()

    local s2 = set(DNA.final_states)
    local s1 = set(DNA.states):remove(s2)
    PI[s1] = true
    PI[s2] = true
    local loop = true
    local divide_label = ""
    local need_divide = false
    local need_divide_set = set()
    while loop do
        for key, value in pairs(PI) do
            -- print(key)
            local need_divide_, label = check_can_divide(PI, key, DNA)

            if need_divide_ then
                divide_label = label
                need_divide = true
                need_divide_set = key
                break
            end
        end
        -- print(need_divide)
        if need_divide then
            divide(DNA, need_divide_set, PI, divide_label)
            need_divide = false
        else
            loop = false
        end
    end
    for key in pairs(PI) do
        PI[key] = {
            is_start = false,
            is_end = false
        }
        for state in pairs(key) do
            if DNA.initial_states:contain(state) then
                PI[key].is_start = true
            end
            if DNA.final_states:contain(state) then
                PI[key].is_end = true
            end
        end
    end
    local new_PI = matrix()
    local convert_table_PI = matrix()
    for key, value in pairs(PI) do
        for state in pairs(key) do
            new_PI[set(state)] = value
            for state1 in pairs(key) do
                convert_table_PI[set(state1)] = set(state)
            end
            break
        end
    end


    local new_mt = matrix()
    DNA.initial_states:remove(DNA.initial_states)
    DNA.final_states:remove(DNA.final_states)
    DNA.states = set()

    for value, label_set in pairs(DNA.transition_matrix) do
        if new_PI[set(value)] then
            new_mt[value] = new_mt[value] or matrix()
            if new_PI[set(value)].is_start then
                DNA.initial_states:insert(value)
            end
            if new_PI[set(value)].is_end then
                DNA.final_states:insert(value)
            end
            for label, state_set in ipairs(label_set) do
                new_mt[value][label] = convert_table_PI[state_set]
            end
        end
    end
    DNA.transition_matrix = new_mt
end
