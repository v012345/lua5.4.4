local set = require "utils.set"
---@type set
local temp_states = nil

---comment
---@param NFA Machine
local function set_temp_states(NFA)
    temp_states = set(NFA.__states)
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

---comment
---@param NFA Machine
local function basic_convert(NFA)
    local __matrix = NFA.__matrix or { { set() } }
    NFA.__chars = set()
    ---@type set[][]
    local matrix = {}
    for from, row in pairs(__matrix) do
        for lable, tos in pairs(row) do
            for to in tos:generator() do
                if lable == "" then -- ε
                    matrix[from] = matrix[from] or {}
                    matrix[from][lable] = matrix[from][lable] or set()
                    matrix[from][lable]:insert(to)
                elseif string.match(lable, '|') then
                    error("nfa2dfa|")
                elseif string.match(lable, '*') then
                    error("nfa2dfa*")
                elseif #lable > 1 then
                    convert_and(NFA, matrix, from, lable, to)
                else
                    NFA.__chars:insert(lable)
                    matrix[from] = matrix[from] or {}
                    matrix[from][lable] = matrix[from][lable] or set()
                    matrix[from][lable]:insert(to)
                end
            end
        end
    end
    NFA.__matrix = matrix
end

---comment
---@param matrix set[][]
---@param states set
---@param result set
---@param has_visited set|nil
local function epsilon_close(matrix, states, result, has_visited)
    has_visited = has_visited or set()
    for state in states:generator() do
        result:insert(state)
        for l, tos in pairs(matrix[state] or {}) do
            for to in tos:generator() do
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
    for state in states:generator() do
        for l, tos in pairs(matrix[state] or {}) do
            if l == a then
                for to in tos:generator() do
                    result:insert(to)
                end
            end
        end
    end
end

---comment
---@param matrix set[][]
---@param state set
---@param a set
---@return table
local function I(matrix, state, a)
    local r = set()
    epsilon_close(matrix, state, r)
    local r1 = set()
    getJ(matrix, r, a, r1)
    r = set()
    epsilon_close(matrix, r1, r)
    return r
end

local function get_converttable(NFA)
    ---@type set[][]
    local convert_table = {}
    if convert_table then
        local row = convert_table[key]
        for k, v in pairs(row) do
            if not convert_table[v] then
                convert_table[v] = {}
                for value in pairs(NFA.__chars) do
                    local a = I(NFA.__matrix, v, value)
                    local b = {}
                    for index in pairs(a) do
                        b[#b + 1] = index
                    end
                    convert_table[v][value] = b
                end
            end
            to_dfa(NFA, convert_table, v)
        end
    else
        convert_table = {}
        local x = {}
        local start = {}

        for k in pairs(NFA.__start) do
            start[#start + 1] = k
        end

        epsilon_close(NFA.__matrix, start, x)
        local temp = {}
        for k in pairs(x) do
            temp[#temp + 1] = k
        end
        convert_table[temp] = convert_table[temp] or {}
        for value in pairs(NFA.__chars) do
            local a = I(NFA.__matrix, temp, value)
            local b = {}
            for index in pairs(a) do
                b[#b + 1] = index
            end
            convert_table[temp][value] = b
        end
        to_dfa(NFA, convert_table, temp)
        return convert_table
    end
end

---comment
---@param NFA Machine
local function nfa2dfa(NFA)
    set_temp_states(NFA)

    local start_state = get_a_state()
    local end_state = get_a_state()
    NFA.__matrix[start_state] = {}
    for state in NFA.__start:generator() do
        NFA.__matrix[start_state][""] = NFA.__matrix[start_state][""] or set()
        NFA.__matrix[start_state][""]:insert(state)
    end
    NFA.__matrix[end_state] = {}
    for state in NFA.__end:generator() do
        NFA.__matrix[state] = NFA.__matrix[state] or {}
        NFA.__matrix[state][""] = NFA.__matrix[state][""] or set()
        NFA.__matrix[state][""]:insert(end_state)
    end
    NFA.__start = set()
    NFA.__end = set()
    NFA.__start:insert(start_state)
    NFA.__end:insert(end_state)
    basic_convert(NFA) -- 还没有完成

    local convert_table = get_converttable(NFA)
    -- for key1, value in pairs(convert_table) do
    --     for key2, v in pairs(key1) do
    --         print(key2, v)
    --     end
    --     for index, value1 in pairs(value) do
    --         print(index, value1)
    --         for key3, value2 in pairs(value1) do
    --             print(key3, value2)
    --         end
    --     end
    -- end
    --
    -- for key, value in pairs(a) do
    --     print(key, value)
    -- end
    NFA.__states = temp_states
end

return nfa2dfa
