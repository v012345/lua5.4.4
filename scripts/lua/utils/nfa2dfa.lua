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
            for to in pairs(tos) do
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

---comment
---@param NFA Machine
local function nfa2dfa(NFA)
    set_temp_states(NFA)

    local start_state = get_a_state()
    local end_state = get_a_state()
    NFA.__matrix[start_state] = {}
    for state in pairs(NFA.__start) do
        NFA.__matrix[start_state][""] = NFA.__matrix[start_state][""] or set()
        NFA.__matrix[start_state][""]:insert(state)
    end
    NFA.__matrix[end_state] = {}
    for state in pairs(NFA.__end) do
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
    for row_name, row in pairs(convert_table) do
        print(row_name)
        for i, v in pairs(row) do
            print(v)
        end
    end
    --
    -- for key, value in pairs(a) do
    --     print(key, value)
    -- end
    NFA.__states = temp_states
end

return nfa2dfa
