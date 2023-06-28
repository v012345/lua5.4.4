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

---comment
---@param NFA Machine
---@param matrix set[][]
---@param from any
---@param lable any
---@param to any
local function convert_and(NFA, matrix, from, lable, to)
    local state_next = get_a_state()

    matrix[from] = matrix[from] or {}
    local c = string.sub(lable, 1, 1)
    matrix[from][c] = matrix[from][c] or set()
    matrix[from][c]:insert(state_next)
    NFA.__chars:insert(c)

    for i = 2, #lable - 1, 1 do
        matrix[state_next] = matrix[state_next] or {}
        local l = string.sub(lable, i, i)
        matrix[state_next][l] = matrix[state_next][l] or set()
        local temp_p = matrix[state_next][l]
        state_next = get_a_state()
        temp_p:insert(state_next)
        NFA.__chars:insert(l)
    end
    matrix[state_next] = matrix[state_next] or {}
    local l = string.sub(lable, #lable, #lable)
    matrix[state_next][l] = matrix[state_next][l] or set()
    matrix[state_next][l]:insert(to)
    NFA.__chars:insert(l)
end

local function need_to_deal(lable)
    if lable == "" then
        return false
    elseif string.match(lable, "^[a-zA-Z]+$") then
        return false
    end
    return true
end

local function need_to_deal_or(lable)
    local level = 0
    local r = {}
    local from = 1
    for i = 1, #lable, 1 do
        local char = string.sub(lable, i, i)
        if char == "(" then
            level = level + 1
        end
        if char == ")" then
            level = level - 1
        end
        if char == "|" and level == 0 then
            r[#r + 1] = string.sub(lable, from, i - 1)
            from = i + 1
        end
    end
    if #r > 0 then
        r[#r + 1] = string.sub(lable, from, #lable)
        return true, set(r)
    end
    return false, set()
end

local function need_to_deal_parentheses(lable)
    local level = 0
    local r = {}
    local from = 1
    local left = 1
    for i = 1, #lable, 1 do
        local char = string.sub(lable, i, i)
        if char == "(" then
            level = level + 1
            if level == 1 then
                left = i
            end
        end
        if char == ")" then
            level = level - 1
            if level == 0 then
                if string.sub(lable, i + 1, i + 1) ~= "*" then
                    local a = string.sub(lable, from, left - 1)
                    if a ~= "" then
                        r[#r + 1] = a
                    end
                    a = string.sub(lable, left + 1, i - 1)
                    if a ~= "" then
                        r[#r + 1] = a
                    end
                    from = i + 1
                end
            end
        end
    end
    if #r > 0 then
        local a = string.sub(lable, from, #lable)
        if a ~= "" then
            r[#r + 1] = a
        end
        return true, r
    end
    return false, r
end

local function deal_or()

end

local function deal_close()

end

local function deal_and()

end

local function deal_parentheses()

end

---comment
---@param NFA NFA
---@param from_state any
---@param to_state any
---@param label any
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
                    new_state[i] = set(get_a_state())
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
            end
        end
    else
        return
    end
end

local function deal_one_state(NFA, state, labels)
    local need_to_deal_states = {}
    for lable, to_state in pairs(labels) do
        need_to_deal_states[lable] = to_state
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
    -- local __matrix = NFA.__matrix or { { set() } }
    -- NFA.__chars = set()
    -- ---@type set[][]
    -- local matrix = {}
    -- for from, row in pairs(__matrix) do
    --     for lable, tos in pairs(row) do
    --         for to in pairs(tos) do
    --             if lable == "" then -- ε
    --                 matrix[from] = matrix[from] or {}
    --                 matrix[from][lable] = matrix[from][lable] or set()
    --                 matrix[from][lable]:insert(to)
    --             elseif string.match(lable, '|') then
    --                 error("nfa2dfa|")
    --             elseif string.match(lable, '*') then
    --                 error("nfa2dfa*")
    --             elseif #lable > 1 then
    --                 convert_and(NFA, matrix, from, lable, to)
    --             else
    --                 NFA.__chars:insert(lable)
    --                 matrix[from] = matrix[from] or {}
    --                 matrix[from][lable] = matrix[from][lable] or set()
    --                 matrix[from][lable]:insert(to)
    --             end
    --         end
    --     end
    -- end
    -- NFA.__matrix = matrix
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
        for lable, tos in pairs(matrix[state] or {}) do
            if lable == a then
                result:insert(tos)
            end
        end
    end
end

---comment
---@param matrix set[][]
---@param state set
---@param a any
---@return set
local function I(matrix, state, a)
    local r = set()
    epsilon_close(matrix, state, r)
    local r1 = set()
    getJ(matrix, r, a, r1)
    r = set()
    epsilon_close(matrix, r1, r)
    return r
end

---comment
---@param NFA Machine
---@return set[][]
local function get_converttable(NFA)
    ---@type set[][]
    local convert_table = {}
    local x = set()
    epsilon_close(NFA.__matrix, NFA.__start, x)
    convert_table[x] = convert_table[x] or {}

    for label in pairs(NFA.__chars) do
        local a = I(NFA.__matrix, x, label)
        convert_table[x][label] = a
    end
    local a = set({ set("A"), set("B") })
    a:insert(set("C"))
    a:insert(set("B"))
    print(a)

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

    basic_convert(NFA) -- 还没有完成

    -- local convert_table = get_converttable(NFA)
    -- for row_name, row in pairs(convert_table) do
    --     print(row_name)
    --     for i, v in pairs(row) do
    --         print(v)
    --     end
    -- end
    --
    -- for key, value in pairs(a) do
    --     print(key, value)
    -- end
    -- NFA.__states = temp_states
end

return nfa2dfa
