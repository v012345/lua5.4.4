local Parser = {}
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


function Parser:escape_string(str)
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

function Parser:get_next_char()
    local _char_pointer = char_pointer
    self.current_char = string.sub(self.dot_string, _char_pointer, _char_pointer)
    _char_pointer = _char_pointer + 1
    char_pointer = _char_pointer
    return self.current_char
end

function Parser:skip_space()
    if not self.current_char then
        self:get_next_char()
    end
    while space[self.current_char] do
        self:get_next_char()
    end
end

function Parser:read_name(Machine)
    self:skip_space() -- 跳过文件开头空白
    local t = {}
    while not space[self.current_char] do
        t[#t + 1] = self.current_char
        self:get_next_char()
    end
    if table.concat(t) ~= "digraph" then
        error("not a digraph")
    end
    t = {}
    self:skip_space()
    while not space[self.current_char] and self.current_char ~= "{" do
        t[#t + 1] = self.current_char
        self:get_next_char()
    end
    Machine.__name = table.concat(t)
    self:skip_space()
end

function Parser:read_rankdir(Machine)
    self:skip_space() -- 跳过文件开头空白
    if self.current_char ~= "=" then
        error("not a rankdir")
    end
    self:get_next_char()
    self:skip_space()
    local t = {}
    t[#t + 1] = self.current_char
    t[#t + 1] = self:get_next_char()
    self:get_next_char()
    self:skip_space()
    Machine.__rankdir = table.concat(t)
    if self.current_char ~= ";" then
        error("not a rankdir")
    end
    self:get_next_char()
end

function Parser:read_a_string()
    local s = {}
    local _char_pointer = char_pointer
    local char = string.sub(self.dot_string, _char_pointer, _char_pointer)
    _char_pointer = _char_pointer + 1

    while char ~= '"' do
        if char == "\\" then
            char = string.sub(self.dot_string, _char_pointer, _char_pointer)
            _char_pointer = _char_pointer +
                1 -- 跳过第一个 "\"
            local escape_char = escape[char]
            if escape_char then
                s[#s + 1] = escape_char
            else
                error(tostring(char) .. " can't escape")
            end
        else
            s[#s + 1] = char
        end
        char = string.sub(self.dot_string, _char_pointer, _char_pointer)
        _char_pointer = _char_pointer + 1
    end
    if char ~= '"' then
        error("string unexcepted end")
    end
    char_pointer = _char_pointer
    self:get_next_char() --跳过结尾 "
    return table.concat(s)
end

function Parser:read_size(Machine)
    self:skip_space() -- 跳过文件开头空白
    if self.current_char ~= "=" then
        error("not a rankdir")
    end
    self:get_next_char()
    self:skip_space()
    local t = self:read_a_string()
    self:skip_space()
    Machine.__size = t
    if self.current_char ~= ";" then
        error("not a size")
    end
    self:get_next_char()
end

function Parser:read_states_and_matrix(Machine)
    self:skip_space() -- 跳过文件开头空白
    while true do
        self:skip_space()
        if self.current_char == "}" then
            return
        else
            local token1 = self:read_a_token()

            Machine.__states = Machine.__states or {}
            Machine.__states[token1] = true
            self:skip_space()
            if self.current_char ~= "-" then
                error("not a struct")
            end
            self:get_next_char()
            if self.current_char ~= ">" then
                error("not a struct")
            end
            self:get_next_char()
            self:skip_space()
            local token2 = self:read_a_token()
            Machine.__states[token2] = true
            local attr = self:read_a_attr()
            if attr.key == "label" then
                Machine.__chars = Machine.__chars or {}
                Machine.__chars[attr.value] = true
                Machine.__matrix = Machine.__matrix or {}
                Machine.__matrix[token1] = Machine.__matrix[token1] or {}
                Machine.__matrix[token1][attr.value] = token2
            end
        end
    end
end

function Parser:read_start_and_end_states(Machine)
    self:skip_space() -- 跳过文件开头空白
    while true do
        local _char_pointer = char_pointer
        local _current_char = self.current_char
        local token = self:read_a_token()
        if token == "node" then
            self.current_char = _current_char
            char_pointer = _char_pointer
            return
        else
            local attr = self:read_a_attr()
            Machine.__states = Machine.__states or {}
            Machine.__states[token] = true
            if attr.key == "color" and attr.value == "green" then
                Machine.__start = Machine.__start or {}
                Machine.__start[token] = true
            elseif attr.key == "color" and attr.value == "red" then
                Machine.__end = Machine.__end or {}
                Machine.__end[token] = true
            end
        end
    end
end

function Parser:read_a_token()
    self:skip_space() -- 跳过文件开头空白
    local t = {}
    while string.match(self.current_char, "[a-zA-Z_0-9]")
    do
        t[#t + 1] = self.current_char
        self:get_next_char()
    end
    return table.concat(t)
end

function Parser:read_a_attr()
    self:skip_space() -- 跳过文件开头空白
    if self.current_char ~= "[" then
        error("not an attr")
    end
    self:get_next_char()
    self:skip_space()
    local token = self:read_a_token()
    local t = { key = token }
    self:skip_space()
    if self.current_char ~= "=" then
        error("not an attr")
    end
    self:get_next_char()
    self:skip_space()
    if self.current_char == "\"" then
        local value = self:read_a_string()
        t.value = value
    else
        local value = self:read_a_token()
        t.value = value
    end
    self:skip_space()
    if self.current_char ~= ";" then
        error("not an attr")
    end
    self:get_next_char()
    self:skip_space()
    if self.current_char ~= "]" then
        error("not an attr")
    end
    self:get_next_char()
    self:skip_space()

    if self.current_char ~= ";" then
        error("not an attr")
    end
    self:get_next_char()
    self:skip_space()
    return t
end

function Parser:read_struct(Machine)
    self:skip_space() -- 跳过文件开头空白
    if self.current_char ~= "{" then
        error("don't have a struct")
    end
    self:get_next_char()
    self:skip_space()
    local token = self:read_a_token()
    while true do
        if token == "rankdir" then
            self:read_rankdir(Machine)
            token = self:read_a_token()
        elseif token == "size" then
            self:read_size(Machine)
            token = self:read_a_token()
        elseif token == "node" then
            self:skip_space()
            if self.current_char ~= "[" then
                error("node doesn't exist attr")
            end
            local attr = self:read_a_attr()
            if attr.key == "shape" and attr.value == "doublecircle" then
                self:read_start_and_end_states(Machine)
            elseif attr.key == "shape" and attr.value == "circle" then
                self:read_states_and_matrix(Machine)
            end
            token = self:read_a_token()
        else
            return Machine
        end
    end
end

function Parser:parser(Machine, dot_string)
    self.dot_string = dot_string
    self:read_name(Machine)
    -- local current_char = self.current_char
    self:skip_space()
    self:read_struct(Machine)
    return Machine
end

return function(dot_string)
    local Machine = {}
    setmetatable(Machine, { __index = Parser })
    local s, r = xpcall(Parser.parser, function(error_msg)
        print(debug.traceback(error_msg))
    end, Parser, Machine, dot_string)
    if s then
        return r
    else
        return nil
    end
end
