local set = require "utils.set"
local matrix = require "utils.matrix"
---@type set
local temp_states = nil

---comment
---@param NFA NFA
local function set_temp_states(NFA)
    temp_states = set(NFA.states)
end

local function get_a_state()
    local x = #temp_states
    repeat
        x = x + 1
    until not temp_states:contain(tostring(x))
    temp_states:insert(tostring(x))
    return tostring(x)
end

local function need_to_deal(label)
    if label == "" then
        return false
    elseif string.match(label, "^[a-zA-Z]+$") then
        return false
    end
    return true
end

local function need_to_deal_or(label)
    local level = 0
    local r = {}
    local from = 1
    for i = 1, #label, 1 do
        local char = string.sub(label, i, i)
        if char == "(" then
            level = level + 1
        end
        if char == ")" then
            level = level - 1
        end
        if char == "|" and level == 0 then
            r[#r + 1] = string.sub(label, from, i - 1)
            from = i + 1
        end
    end
    if #r > 0 then
        r[#r + 1] = string.sub(label, from, #label)
        return true, set(r)
    end
    return false, set()
end

local function need_to_deal_parentheses(label)
    local level = 0
    local r = {}
    local from = 1
    local left = 1
    for i = 1, #label, 1 do
        local char = string.sub(label, i, i)
        if char == "(" then
            level = level + 1
            if level == 1 then
                left = i
            end
        end
        if char == ")" then
            level = level - 1
            if level == 0 then
                if string.sub(label, i + 1, i + 1) ~= "*" then
                    local a = string.sub(label, from, left - 1)
                    if a ~= "" then
                        r[#r + 1] = a
                    end
                    a = string.sub(label, left + 1, i - 1)
                    if a ~= "" then
                        r[#r + 1] = a
                    end
                    from = i + 1
                end
            end
        end
    end
    if #r > 0 then
        local a = string.sub(label, from, #label)
        if a ~= "" then
            r[#r + 1] = a
        end
        return true, r
    end
    return false, r
end

local function need_to_deal_close(label)
    local level = 0
    local r = {}
    local from = 1
    for i = 1, #label, 1 do
        local char = string.sub(label, i, i)
        if char == "(" then
            level = level + 1
            if level == 1 then
                local a = string.sub(label, from, i - 1)
                if a ~= "" then
                    r[#r + 1] = {
                        is_close = false,
                        label = a
                    }
                end
                from = i + 1
            end
        end
        if char == ")" then
            level = level - 1
            if level == 0 then
                if string.sub(label, i + 1, i + 1) == "*" then
                    local a = string.sub(label, from - 1, i + 1)
                    if a ~= "" then
                        r[#r + 1] = {
                            is_close = true,
                            label = a
                        }
                    end
                    from = i + 2
                else
                    error("not a close")
                end
            end
        end
        if char == "*" then
            if string.sub(label, i - 1, i - 1) ~= ")" and level == 0 then
                local a = string.sub(label, from, i - 2)
                if a ~= "" then
                    r[#r + 1] = {
                        is_close = false,
                        label = a
                    }
                end
                from = i - 1
                a = string.sub(label, from, i)
                if a ~= "" then
                    r[#r + 1] = {
                        is_close = true,
                        label = a
                    }
                end
                from = i + 1
            end
        end
    end
    if #r > 0 then
        return true, r
    end
    return false, r
end


---comment
---@param NFA NFA
---@param from_state string
---@param to_state set
---@param label string
local function deal_on_label(NFA, from_state, to_state, label)
    if need_to_deal(label) then
        local need_or, data_or = need_to_deal_or(label)
        if need_or then
            NFA.transition_matrix[from_state][label] = nil
            for new_lable in pairs(data_or) do
                NFA.transition_matrix[from_state][new_lable] = to_state
                deal_on_label(NFA, from_state, to_state, new_lable)
            end
        else
            local need_parentheses, data_parentheses = need_to_deal_parentheses(label)
            if need_parentheses then
                NFA.transition_matrix[from_state][label] = nil
                local new_state = {}
                for i = 1, #data_parentheses - 1 do
                    new_state[i] = get_a_state()
                end
                new_state[#new_state + 1] = to_state
                for key, new_lable in pairs(data_parentheses) do
                    if key == 1 then
                        NFA.transition_matrix[from_state][new_lable] = new_state[key]
                        deal_on_label(NFA, from_state, new_state[key], new_lable)
                    else
                        NFA.transition_matrix[new_state[key - 1]] = NFA.transition_matrix[new_state[key - 1]] or {}
                        NFA.transition_matrix[new_state[key - 1]][new_lable] = new_state[key]
                        deal_on_label(NFA, new_state[key - 1], new_state[key], new_lable)
                    end
                end
            else
                local need_close, data_close = need_to_deal_close(label)
                if need_close then
                    if #data_close > 1 then
                        NFA.transition_matrix[from_state][label] = nil
                        local new_state = {}
                        new_state[#new_state + 1] = from_state
                        for i = 1, #data_close - 1 do
                            new_state[#new_state + 1] = get_a_state()
                        end
                        new_state[#new_state + 1] = to_state
                        for key, value in pairs(data_close) do
                            local new_lable = value.label
                            local transition_matrix = NFA.transition_matrix
                            transition_matrix[new_state[key]] = transition_matrix[new_state[key]] or {}
                            NFA.transition_matrix[new_state[key]][new_lable] = new_state[key + 1]
                            deal_on_label(NFA, new_state[key], new_state[key + 1], new_lable)
                        end
                    else
                        NFA.transition_matrix[from_state][label] = nil
                        local new_state = get_a_state()
                        for key, value in pairs(data_close) do
                            local new_lable = value.label
                            local transition_matrix = NFA.transition_matrix
                            transition_matrix[new_state] = transition_matrix[new_state] or {}
                            NFA.transition_matrix[from_state][""] = new_state
                            NFA.transition_matrix[new_state][string.sub(new_lable, 1, #new_lable - 1)] = new_state
                            NFA.transition_matrix[new_state][""] = to_state
                            deal_on_label(NFA, new_state, new_state, string.sub(new_lable, 1, #new_lable - 1))
                        end
                    end
                end
            end
        end
    else
        if #label > 1 then
            NFA.transition_matrix[from_state][label] = nil
            local new_state = {}
            new_state[#new_state + 1] = from_state
            for i = 1, #label - 1 do
                new_state[#new_state + 1] = get_a_state()
            end
            new_state[#new_state + 1] = to_state
            for i = 1, #label, 1 do
                local new_lable = string.sub(label, i, i)
                local transition_matrix = NFA.transition_matrix
                transition_matrix[new_state[i]] = transition_matrix[new_state[i]] or {}
                NFA.transition_matrix[new_state[i]][new_lable] = new_state[i + 1]
            end
        end
        return
    end
end

local function deal_one_state(NFA, state, labels)
    local need_to_deal_states = {}
    for label, to_state in pairs(labels) do
        need_to_deal_states[label] = to_state
    end
    for label, to_state in pairs(need_to_deal_states) do
        deal_on_label(NFA, state, to_state, label)
    end
end

---comment
---@param NFA NFA
local function basic_convert(NFA)
    local need_to_deal_states = {}
    for key in pairs(NFA.transition_matrix) do
        need_to_deal_states[#need_to_deal_states + 1] = key
    end

    for _, state in pairs(need_to_deal_states) do
        deal_one_state(NFA, state, NFA.transition_matrix[state])
    end
end

---comment
---@param matrix set[][]
---@param states set
---@param result set
---@param has_visited set|nil
local function epsilon_close(matrix, states, result, has_visited)
    has_visited = has_visited or set()
    for state in pairs(states) do
        result:insert(state)
        for l, tos in pairs(matrix[state] or {}) do
            if type(tos) == "table" then
                for to in pairs(tos) do
                    if l == "" then
                        result:insert(to)
                        if has_visited:contain(to) then
                            goto con
                        end
                        has_visited:insert(to)
                        epsilon_close(matrix, set(to), result, has_visited)
                    end
                    :: con ::
                end
            else
                local to = tos
                if l == "" then
                    result:insert(to)
                    has_visited:insert(to)
                    epsilon_close(matrix, set(to), result, has_visited)
                end
            end
        end
    end
end

---comment
---@param matrix set[][]
---@param states set
---@param a any
---@param result set
local function getJ(matrix, states, a, result)
    for state in pairs(states) do
        for label, tos in pairs(matrix[state] or {}) do
            if label == a then
                result:insert(tos)
            end
        end
    end
end

---comment
---@param matrix_ set[][]
---@param state set
---@param a any
---@return set
local function I(matrix_, state, a)
    local r = set()


    epsilon_close(matrix_, state, r)

    local r1 = set()
    getJ(matrix_, r, a, r1)

    r = set()
    epsilon_close(matrix_, r1, r)
    return r
end

---comment
---@param NFA NFA
---@return set[][]
local function get_converttable(NFA)
    local chars = set()
    for _, label_states in pairs(NFA.transition_matrix) do
        for label, _ in pairs(label_states) do
            if label ~= "" then
                chars:insert(label)
            end
        end
    end
    ---@type set[][]
    local convert_table = {}
    local first_line_key = set()
    epsilon_close(NFA.transition_matrix, NFA.initial_states, first_line_key)

    local function gg(convert_table1, line_key)
        print(line_key)
        print(convert_table1[line_key])
        if convert_table1[line_key] then
            return
        else
            for a in pairs(chars) do
                -- print(line_key)
                local Ia = I(NFA.transition_matrix, line_key, a)
                convert_table1[line_key] = convert_table1[line_key] or {}
                convert_table1[line_key][a] = Ia
                -- print(Ia)
            end
            for key, value in pairs(convert_table1[line_key]) do
                if #value ~= 0 then
                    gg(convert_table1, value)
                end
            end
        end
    end
    -- print(NFA.transition_matrix[set("5")])
    gg(convert_table, first_line_key)
    for index, value in ipairs(convert_table) do
        print(index)
        for key, value1 in pairs(value) do
            print(value1)
        end
    end
    -- print("Ia = ", I(NFA.transition_matrix, set({ "5", "1", "9" }), "a"))
    return convert_table
end

local function add_new_start_and_end(NFA)
    local start_state = get_a_state()
    local end_state = get_a_state()
    NFA.transition_matrix[start_state] = matrix()
    for state in pairs(NFA.initial_states) do
        NFA.transition_matrix[start_state][""] = NFA.transition_matrix[start_state][""] or set()
        NFA.transition_matrix[start_state][""]:insert(state)
    end
    NFA.transition_matrix[end_state] = matrix()
    for state in pairs(NFA.final_states) do
        NFA.transition_matrix[state] = NFA.transition_matrix[state] or matrix()
        NFA.transition_matrix[state][""] = NFA.transition_matrix[state][""] or set()
        NFA.transition_matrix[state][""]:insert(end_state)
    end
    NFA.initial_states:remove(NFA.initial_states):insert(start_state)
    NFA.final_states:remove(NFA.final_states):insert(end_state)
end

---comment
---@param NFA NFA
local function nfa2dfa(NFA)
    set_temp_states(NFA)
    add_new_start_and_end(NFA)

    basic_convert(NFA)

    -- local convert_table = get_converttable(NFA)
end

return nfa2dfa
