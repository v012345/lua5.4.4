local set = require "utils.set"
local nfa = require "utils.nfa"
local matrix = require "utils.matrix"
---@class Machine
local mt = {}
local space = {
    [" "] = " ",
    ["\t"] = "\t",
    ["\n"] = "\n",
    ["\f"] = "\f",
    ["\v"] = "\v",
}
local escape = {
    ["\\"] = "\\",
    ["\""] = "\"",
    ["/"] = "/",
    ["r"] = "\r",
    ["f"] = "\f",
    ["n"] = "\n",
    ["t"] = "\t",
    ["b"] = "\b",
}

local char_pointer = 1
local dot_string = ""
local current_char = " "


local function get_next_char()
    local _char_pointer = char_pointer
    current_char = string.sub(dot_string, _char_pointer, _char_pointer)
    _char_pointer = _char_pointer + 1
    char_pointer = _char_pointer
    return current_char
end

local function skip_space()
    while space[current_char] do
        get_next_char()
    end
end

local function read_name()
    skip_space() -- 跳过文件开头空白
    local t = {}
    while not space[current_char] do
        t[#t + 1] = current_char
        get_next_char()
    end
    if table.concat(t) ~= "digraph" then
        error("not a digraph")
    end
    t = {}
    skip_space()
    while not space[current_char] and current_char ~= "{" do
        t[#t + 1] = current_char
        get_next_char()
    end
    skip_space()
end


local function read_rankdir()
    skip_space() -- 跳过文件开头空白
    if current_char ~= "=" then
        error("not a rankdir")
    end
    get_next_char()
    skip_space()
    local t = {}
    t[#t + 1] = current_char
    t[#t + 1] = get_next_char()
    get_next_char()
    skip_space()
    if current_char ~= ";" then
        error("not a rankdir")
    end
    get_next_char()
end

---@return string
local function read_a_string()
    local s = {}
    local _char_pointer = char_pointer
    local char = string.sub(dot_string, _char_pointer, _char_pointer)
    _char_pointer = _char_pointer + 1

    while char ~= '"' do
        if char == "\\" then
            char = string.sub(dot_string, _char_pointer, _char_pointer)
            _char_pointer = _char_pointer + 1 -- 跳过第一个 "\"
            local escape_char = escape[char]
            if escape_char then
                s[#s + 1] = escape_char
            else
                error(tostring(char) .. " can't escape")
            end
        else
            s[#s + 1] = char
        end
        char = string.sub(dot_string, _char_pointer, _char_pointer)
        _char_pointer = _char_pointer + 1
    end
    if char ~= '"' then
        error("string unexcepted end")
    end
    char_pointer = _char_pointer
    get_next_char() --跳过结尾 "
    return table.concat(s)
end

local function read_size()
    skip_space() -- 跳过文件开头空白
    if current_char ~= "=" then
        error("not a rankdir")
    end
    get_next_char()
    skip_space()
    local t = read_a_string()
    skip_space()
    if current_char ~= ";" then
        error("not a size")
    end
    get_next_char()
end

---comment
---@return string
local function read_a_token()
    skip_space() -- 跳过文件开头空白
    local t = {}
    while string.match(current_char, "[a-zA-Z_0-9]")
    do
        t[#t + 1] = current_char
        get_next_char()
    end
    return table.concat(t)
end

---comment
---@return table
local function read_a_attr()
    skip_space() -- 跳过文件开头空白
    if current_char ~= "[" then
        error("not an attr")
    end
    get_next_char()
    skip_space()
    local token = read_a_token()
    local t = { key = token }
    skip_space()
    if current_char ~= "=" then
        error("not an attr")
    end
    get_next_char()
    skip_space()
    if current_char == "\"" then
        local value = read_a_string()
        t.value = value
    else
        local value = read_a_token()
        t.value = value
    end
    skip_space()
    if current_char ~= ";" then
        error("not an attr")
    end
    get_next_char()
    skip_space()
    if current_char ~= "]" then
        error("not an attr")
    end
    get_next_char()
    skip_space()

    if current_char ~= ";" then
        error("not an attr")
    end
    get_next_char()
    skip_space()
    return t
end

---comment
---@param Machine NFA
local function read_states_and_matrix(Machine)
    skip_space() -- 跳过文件开头空白
    while true do
        skip_space()
        if current_char == "}" then
            return
        else
            local token1 = read_a_token()
            Machine:add_states(token1)
            skip_space()
            if current_char ~= "-" then
                error("not a struct")
            end
            get_next_char()
            if current_char ~= ">" then
                error("not a struct")
            end
            get_next_char()
            skip_space()
            local token2 = read_a_token()
            Machine:add_states(token2)
            local attr = read_a_attr()
            if attr.key == "label" then
                Machine:add_char(attr.value) -- 这里有问题
                Machine.transition_matrix[token1] = Machine.transition_matrix[token1] or matrix()
                Machine.transition_matrix[token1][attr.value] = Machine.transition_matrix[token1][attr.value] or set()
                Machine.transition_matrix[token1][attr.value]:insert(token2)
            end
        end
    end
end

---comment
---@param Machine NFA
local function read_start_and_end_states(Machine)
    skip_space() -- 跳过文件开头空白
    while true do
        local _char_pointer = char_pointer
        local _current_char = current_char
        local token = read_a_token()
        if token == "node" then
            current_char = _current_char
            char_pointer = _char_pointer
            return
        else
            local attr = read_a_attr()
            Machine:add_states(token)
            if attr.key == "color" and attr.value == "green" then
                Machine:add_initial_states(token)
            elseif attr.key == "color" and attr.value == "red" then
                Machine:add_final_states(token)
            end
        end
    end
end



---comment
---@param Machine NFA
---@return NFA
local function read_struct(Machine)
    skip_space() -- 跳过文件开头空白
    if current_char ~= "{" then
        error("don't have a struct")
    end
    get_next_char()
    skip_space()
    local token = read_a_token()
    while true do
        if token == "rankdir" then
            read_rankdir()
            token = read_a_token()
        elseif token == "size" then
            read_size()
            token = read_a_token()
        elseif token == "node" then
            skip_space()
            if current_char ~= "[" then
                error("node doesn't exist attr")
            end
            local attr = read_a_attr()
            if attr.key == "shape" and attr.value == "doublecircle" then
                read_start_and_end_states(Machine)
            elseif attr.key == "shape" and attr.value == "circle" then
                read_states_and_matrix(Machine)
            end
            token = read_a_token()
        else
            return Machine
        end
    end
end


---comment
---@param Machine NFA
---@param raw_content string
---@return NFA
local function parser(Machine, raw_content)
    dot_string = raw_content
    read_name()
    skip_space()
    read_struct(Machine)
    return Machine
end

---comment
---@param raw_content string
---@return NFA
return function(raw_content)
    local Machine = nfa()
    return parser(Machine, raw_content)
end
