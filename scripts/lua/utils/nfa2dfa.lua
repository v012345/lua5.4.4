local temp_states = {}

local function set_temp_states(NFA)
    for key, value in pairs(NFA.__states) do
        temp_states[key] = value
    end
    return temp_states
end

local function get_a_state()
    local x = #temp_states
    repeat
        x = x + 1
    until not temp_states[tostring(x)]
    temp_states[tostring(x)] = true
    return tostring(x)
end

local function convert_and(NFA, matrix, from, lable, to)
    local state_next = get_a_state()

    matrix[from] = matrix[from] or {}
    local c = string.sub(lable, 1, 1)
    matrix[from][c] = matrix[from][c] or {}
    matrix[from][c][state_next] = true
    NFA.__chars[c] = true

    for i = 2, #lable - 1, 1 do
        matrix[state_next] = matrix[state_next] or {}
        local l = string.sub(lable, i, i)
        matrix[state_next][l] = matrix[state_next][l] or {}
        local temp_p = matrix[state_next][l]
        state_next = get_a_state()
        temp_p[state_next] = true
        NFA.__chars[l] = true
    end
    matrix[state_next] = matrix[state_next] or {}
    local l = string.sub(lable, #lable, #lable)
    matrix[state_next][l] = matrix[state_next][l] or {}
    matrix[state_next][l][to] = true
    NFA.__chars[l] = true
end

local function basic_convert(NFA)
    local __matrix = NFA.__matrix
    NFA.__chars = {}
    local matrix = {}
    for from, row in pairs(__matrix) do
        for lable, tos in pairs(row) do
            for to, _ in pairs(tos) do
                if lable == "" then -- ε
                    matrix[from] = matrix[from] or {}
                    matrix[from][lable] = matrix[from][lable] or {}
                    matrix[from][lable][to] = true
                elseif string.match(lable, '|') then
                    error("nfa2dfa|")
                elseif string.match(lable, '*') then
                    error("nfa2dfa*")
                elseif #lable > 1 then
                    convert_and(NFA, matrix, from, lable, to)
                else
                    NFA.__chars[lable] = true
                    matrix[from] = matrix[from] or {}
                    matrix[from][lable] = matrix[from][lable] or {}
                    matrix[from][lable][to] = true
                end
            end
        end
    end
    NFA.__matrix = matrix
end

local function epsilon_close(matrix, states, result, has_visited)
    has_visited = has_visited or {}
    for _, state in pairs(states) do
        result[state] = true
        for l, tos in pairs(matrix[state] or {}) do
            for to, _ in pairs(tos) do
                if l == "" then
                    result[to] = true
                    if has_visited[to] then
                        goto con
                    end
                    has_visited[to] = true
                    epsilon_close(matrix, { to }, result, has_visited)
                end
                :: con ::
            end
        end
    end
end

local function getJ(matrix, states, a, result)
    for _, state in pairs(states) do
        for l, tos in pairs(matrix[state] or {}) do
            if l == a then
                for to, _ in pairs(tos) do
                    result[to] = true
                end
            end
        end
    end
end

local function I(matrix, state, a)
    local r = {}
    if type(state) == "table" then
        epsilon_close(matrix, state, r)
    else
        epsilon_close(matrix, { state }, r)
    end
    epsilon_close(matrix, { state }, r)
    local t = {}
    for key, _ in pairs(r) do
        t[#t + 1] = key
    end
    local r1 = {}
    getJ(matrix, t, a, r1)
    t = {}
    for key, _ in pairs(r1) do
        t[#t + 1] = key
    end
    r = {}
    epsilon_close(matrix, t, r)
    return r
end

local function is_eq(list1, list2)
    if #list1 ~= #list2 then
        return false
    end
    local r_1 = {}
    for index, value in ipairs(list1) do
        r_1[value] = index
    end
    for index, value in ipairs(list2) do
        if not r_1[value] then
            return false
        end
    end
    return true
end

local function to_dfa(NFA, convert_table, key)
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

local function nfa2dfa(NFA)
    set_temp_states(NFA)

    local start_state = get_a_state()
    local end_state = get_a_state()
    NFA.__matrix[start_state] = {}
    for state, value in pairs(NFA.__start) do
        NFA.__matrix[start_state][""] = NFA.__matrix[start_state][""] or {}
        NFA.__matrix[start_state][""][state] = true
    end
    NFA.__matrix[end_state] = {}
    for state, value in pairs(NFA.__end) do
        NFA.__matrix[state] = NFA.__matrix[state] or {}
        NFA.__matrix[state][""] = NFA.__matrix[state][""] or {}
        NFA.__matrix[state][""][end_state] = true
    end
    NFA.__start = {}
    NFA.__end = {}
    NFA.__start[start_state] = true
    NFA.__end[end_state] = true
    basic_convert(NFA) -- 还没有完成

    local convert_table = to_dfa(NFA)
    for key1, value in pairs(convert_table) do
        for key2, v in pairs(key1) do
            print(key2, v)
        end
        for index, value1 in pairs(value) do
            print(index, value1)
            for key3, value2 in pairs(value1) do
                print(key3, value2)
            end
        end
    end
    --
    -- for key, value in pairs(a) do
    --     print(key, value)
    -- end
    NFA.__states = temp_states
end

return nfa2dfa
