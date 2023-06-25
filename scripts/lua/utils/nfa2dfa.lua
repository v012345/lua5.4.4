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

local function convert_and(matrix, from, lable, to)
    local state_next = get_a_state()

    matrix[from] = matrix[from] or {}
    matrix[from][string.sub(lable, 1, 1)] = state_next

    for i = 2, #lable - 1, 1 do
        print(i)
        matrix[state_next] = matrix[state_next] or {}
        local l = string.sub(lable, i, i)
        matrix[state_next][l] = get_a_state()
        state_next = matrix[state_next][l]
    end
    matrix[state_next] = matrix[state_next] or {}
    matrix[state_next][string.sub(lable, #lable, #lable)] = to
end

local function basic_convert(NFA)
    local __matrix = NFA.__matrix
    local matrix = {}
    for from, row in pairs(__matrix) do
        for lable, to in pairs(row) do
            if lable == "" then -- ε
                matrix[from] = matrix[from] or {}
                matrix[from][lable] = to
            elseif string.match(lable, '|') then
                error("nfa2dfa|")
            elseif string.match(lable, '*') then
                error("nfa2dfa*")
            elseif #lable > 1 then
                convert_and(matrix, from, lable, to)
            else
                matrix[from] = matrix[from] or {}
                matrix[from][lable] = to
            end
        end
    end
    NFA.__matrix = matrix
end

local function nfa2dfa(NFA)
    set_temp_states(NFA)
    local start_state = get_a_state()
    local end_state = get_a_state()
    NFA.__matrix[start_state] = {}
    for state, value in pairs(NFA.__start) do
        NFA.__matrix[start_state][""] = state
    end
    NFA.__matrix[end_state] = {}
    for state, value in pairs(NFA.__end) do
        NFA.__matrix[state][""] = end_state
    end
    NFA.__start = {}
    NFA.__end = {}
    NFA.__start[start_state] = true
    NFA.__end[end_state] = true
    basic_convert(NFA)
end

return nfa2dfa
