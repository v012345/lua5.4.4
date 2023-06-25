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

local function nfa2dfa(NFA)
    local DFA = {}
    DFA.__name = NFA.__name
    DFA.__size = NFA.__size
    DFA.__rankdir = NFA.__rankdir
    set_temp_states(NFA)
    local start_state         = get_a_state()
    local end_state           = get_a_state()
    DFA.__start               = {}
    DFA.__end                 = {}
    DFA.__start[start_state]  = true
    DFA.__end[end_state]      = true
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
    -- for from, row in pairs(NFA.__matrix) do
    --     for lable, to in pairs(row) do
    --         if lable == "" then -- ε
    --         elseif string.match(lable, '|') then
    --             error("nfa2dfa|")
    --         elseif string.match(lable, '*') then
    --             error("nfa2dfa*")
    --         elseif #lable > 1 then
    --         end
    --     end
    -- end
    return DFA
end

return nfa2dfa
