local set = require "utils.set"
local nfa = require "utils.nfa"
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
local escape_r = {
    ["\\"] = "\\\\",
    ["\""] = "\\\"",
    ["/"] = "\\/",
    ["\r"] = "\\r",
    ["\f"] = "\\f",
    ["\n"] = "\\n",
    ["\t"] = "\\t",
    ["\b"] = "\\b",
}

local char_pointer = 1
local dot_string = ""
local current_char = " "


function mt.escape_string(Machine, str)
    local o = {}
    for i = 1, #str do
        local char = string.sub(str, i, i)
        if escape_r[char] then
            o[i] = escape_r[char]
        else
            o[i] = char
        end
    end
    return table.concat(o)
end

function mt.get_next_char()
    local _char_pointer = char_pointer
    current_char = string.sub(dot_string, _char_pointer, _char_pointer)
    _char_pointer = _char_pointer + 1
    char_pointer = _char_pointer
    return current_char
end

---comment
---@param Machine Machine
function mt.skip_space(Machine)
    while space[current_char] do
        Machine:get_next_char()
    end
end

function mt.read_name(Machine)
    Machine:skip_space() -- 跳过文件开头空白
    local t = {}
    while not space[current_char] do
        t[#t + 1] = current_char
        Machine:get_next_char()
    end
    if table.concat(t) ~= "digraph" then
        error("not a digraph")
    end
    t = {}
    Machine:skip_space()
    while not space[current_char] and current_char ~= "{" do
        t[#t + 1] = current_char
        Machine:get_next_char()
    end
    Machine.__name = table.concat(t)
    Machine:skip_space()
end

---comment
---@param Machine Machine
function mt.read_rankdir(Machine)
    Machine:skip_space() -- 跳过文件开头空白
    if current_char ~= "=" then
        error("not a rankdir")
    end
    Machine:get_next_char()
    Machine:skip_space()
    local t = {}
    t[#t + 1] = current_char
    t[#t + 1] = Machine:get_next_char()
    Machine:get_next_char()
    Machine:skip_space()
    Machine.__rankdir = table.concat(t)
    if current_char ~= ";" then
        error("not a rankdir")
    end
    Machine:get_next_char()
end

---comment
---@param Machine Machine
---@return string
function mt.read_a_string(Machine)
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
    Machine:get_next_char() --跳过结尾 "
    return table.concat(s)
end

function mt.read_size(Machine)
    Machine:skip_space() -- 跳过文件开头空白
    if current_char ~= "=" then
        error("not a rankdir")
    end
    Machine:get_next_char()
    Machine:skip_space()
    local t = Machine:read_a_string()
    Machine:skip_space()
    Machine.__size = t
    if current_char ~= ";" then
        error("not a size")
    end
    Machine:get_next_char()
end

function mt.read_states_and_matrix(Machine)
    Machine:skip_space() -- 跳过文件开头空白
    while true do
        Machine:skip_space()
        if current_char == "}" then
            return
        else
            local token1 = Machine:read_a_token()


            Machine.__states = Machine.__states or set()
            Machine.__states:insert(token1)
            Machine:skip_space()
            if current_char ~= "-" then
                error("not a struct")
            end
            Machine:get_next_char()
            if current_char ~= ">" then
                error("not a struct")
            end
            Machine:get_next_char()
            Machine:skip_space()
            local token2 = Machine:read_a_token()
            Machine.__states:insert(token2)
            local attr = Machine:read_a_attr()
            if attr.key == "label" then
                Machine.__chars = Machine.__chars or set()
                Machine.__chars:insert(attr.value) -- 这里有问题
                Machine.__matrix = Machine.__matrix or {}
                Machine.__matrix[token1] = Machine.__matrix[token1] or {}
                Machine.__matrix[token1][attr.value] = Machine.__matrix[token1][attr.value] or set()
                Machine.__matrix[token1][attr.value]:insert(token2)
            end
        end
    end
end

function mt.read_start_and_end_states(Machine)
    Machine:skip_space() -- 跳过文件开头空白
    while true do
        local _char_pointer = char_pointer
        local _current_char = current_char
        local token = Machine:read_a_token()
        if token == "node" then
            current_char = _current_char
            char_pointer = _char_pointer
            return
        else
            local attr = Machine:read_a_attr()
            Machine.__states = Machine.__states or set()
            Machine.__states:insert(token)
            if attr.key == "color" and attr.value == "green" then
                Machine.__start = Machine.__start or set()
                Machine.__start:insert(token)
            elseif attr.key == "color" and attr.value == "red" then
                Machine.__end = Machine.__end or set()
                Machine.__end:insert(token)
            end
        end
    end
end

---comment
---@param Machine Machine
---@return string
function mt.read_a_token(Machine)
    Machine:skip_space() -- 跳过文件开头空白
    local t = {}
    while string.match(current_char, "[a-zA-Z_0-9]")
    do
        t[#t + 1] = current_char
        Machine:get_next_char()
    end
    return table.concat(t)
end

---comment
---@param Machine Machine
---@return table
function mt.read_a_attr(Machine)
    Machine:skip_space() -- 跳过文件开头空白
    if current_char ~= "[" then
        error("not an attr")
    end
    Machine:get_next_char()
    Machine:skip_space()
    local token = Machine:read_a_token()
    local t = { key = token }
    Machine:skip_space()
    if current_char ~= "=" then
        error("not an attr")
    end
    Machine:get_next_char()
    Machine:skip_space()
    if current_char == "\"" then
        local value = Machine:read_a_string()
        t.value = value
    else
        local value = Machine:read_a_token()
        t.value = value
    end
    Machine:skip_space()
    if current_char ~= ";" then
        error("not an attr")
    end
    Machine:get_next_char()
    Machine:skip_space()
    if current_char ~= "]" then
        error("not an attr")
    end
    Machine:get_next_char()
    Machine:skip_space()

    if current_char ~= ";" then
        error("not an attr")
    end
    Machine:get_next_char()
    Machine:skip_space()
    return t
end

---comment
---@param Machine Machine
---@return any
function mt.read_struct(Machine)
    Machine:skip_space() -- 跳过文件开头空白
    if current_char ~= "{" then
        error("don't have a struct")
    end
    Machine:get_next_char()
    Machine:skip_space()
    local token = Machine:read_a_token()
    while true do
        if token == "rankdir" then
            Machine:read_rankdir()
            token = Machine:read_a_token()
        elseif token == "size" then
            Machine:read_size()
            token = Machine:read_a_token()
        elseif token == "node" then
            Machine:skip_space()
            if current_char ~= "[" then
                error("node doesn't exist attr")
            end
            local attr = Machine:read_a_attr()
            if attr.key == "shape" and attr.value == "doublecircle" then
                Machine:read_start_and_end_states()
            elseif attr.key == "shape" and attr.value == "circle" then
                Machine:read_states_and_matrix()
            end
            token = Machine:read_a_token()
        else
            return Machine
        end
    end
end

---comment
---@param Machine Machine
---@param raw_content string
---@return Machine
function mt.parser(Machine, raw_content)
    dot_string = raw_content
    Machine:read_name()
    Machine:skip_space()
    Machine:read_struct()
    return Machine
end

---comment
---@param Machine Machine
---@param path any
function mt.output(Machine, path)
    local file = io.open(path, "w") or error("can't open file")
    file:write("digraph " .. Machine.__name .. " {\n")
    file:write("    rankdir = " .. Machine.__rankdir .. ";\n")
    file:write(string.format("    size = \"%s\";\n", Machine.__size))
    file:write(string.format("    node [shape = doublecircle;];\n"))
    for k in pairs(Machine.__start) do
        file:write(string.format("    %s [color = green;];\n", k))
    end
    for k in pairs(Machine.__end) do
        file:write(string.format("    %s [color = red;];\n", k))
    end
    file:write(string.format("    node [shape = circle;];\n"))
    for from, row in pairs(Machine.__matrix) do
        for lable, tos in pairs(row) do
            for to in pairs(tos) do
                file:write(string.format("    %s -> %s [label = \"%s\";];\n", from, to, Machine:escape_string(lable)))
            end
        end
    end
    file:write("}\n")
    file:close()
end

---comment
---@param raw_content string
---@return Machine
return function(raw_content)
    ---@class Machine
    local Machine = {
        __name = "",
        __rankdir = "",
        __size = "",
        ---@type set
        __states = nil,
        ---@type set
        __chars = nil,
        ---@type set[][]
        __matrix = nil,
        ---@type set
        __start = nil,
        ---@type set
        __end = nil
    }
    setmetatable(Machine, { __index = mt })
    return Machine:parser(raw_content)
end
