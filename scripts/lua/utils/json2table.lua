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

local concat = table.concat

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
    return concat(o)
end

function Parser:get_next_char()
    local _char_pointer = char_pointer
    self.current_char = string.sub(self.json_string, _char_pointer, _char_pointer)
    _char_pointer = _char_pointer + 1
    char_pointer = _char_pointer
    return self.current_char
end

function Parser:read_a_string()
    local s = {}
    local _char_pointer = char_pointer
    local char = string.sub(self.json_string, _char_pointer, _char_pointer)
    _char_pointer = _char_pointer + 1

    while char ~= '"' do
        if char == "\\" then
            char = string.sub(self.json_string, _char_pointer, _char_pointer)
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
        char = string.sub(self.json_string, _char_pointer, _char_pointer)
        _char_pointer = _char_pointer + 1
    end
    if char ~= '"' then
        error("string unexcepted end")
    end
    char_pointer = _char_pointer
    self:get_next_char() --跳过结尾 "
    return concat(s)
end

function Parser:read_a_key()
    return self:read_a_string()
end

function Parser:read_a_value()
    local value = nil
    local current_char = self.current_char
    if current_char == "\"" then
        value = self:read_a_string()
    elseif current_char == "[" then
        value = self:read_an_array()
    elseif current_char == "{" then
        value = self:read_a_json_object()
    else
        value = self:read_a_base_type()
    end
    return value
end

function Parser:read_an_array()
    self:get_next_char() -- 跳过 [
    self:skip_space()    -- 跳过 [ 后的空白
    local mt = {
        is_array = true
    }
    local result = {}
    local len = 1
    setmetatable(result, mt)
    while self.current_char do
        if self.current_char == '"' then
            result[len] = self:read_a_string()
            len = len + 1
        elseif space[self.current_char] then
            self:get_next_char()
        elseif self.current_char == "{" then
            result[len] = self:read_a_json_object()
            len = len + 1
        elseif self.current_char == "," then
            self:get_next_char() -- 跳过 ,
            self:skip_space()
            if self.current_char == "]" then
                error("the last element has a , follow")
            end
        elseif self.current_char == "]" then
            break
        elseif self.current_char == "[" then
            result[len] = self:read_an_array()
            len = len + 1
        else
            result[len] = self:read_a_base_type()
            len = len + 1
        end
    end
    self:get_next_char() -- 跳过 ]
    self:skip_space()    -- 跳过文件结束空白
    if self.current_char == "," then
        self:get_next_char()
    end
    return result
end

function Parser:read_a_base_type()
    local s = {}
    local r, i = true, 1
    while self.current_char and string.find(self.current_char, "[0-9aeflnrstu%.%-]") do
        s[#s + 1] = self.current_char
        self:get_next_char()
    end
    local token = concat(s)
    if token == "true" then
        -- r = true
    elseif token == "null" then
        r = nil
    elseif token == "false" then
        r = false
    else
        local n = tonumber(token) -- todo 这里有问题, 比 json 规定的数字范围大
        if n then
            r = n
        else
            error("not a base type")
        end
    end
    self:skip_space()
    if self.current_char then
        if self.current_char ~= "," and
            self.current_char ~= "]" and
            self.current_char ~= "}"
        then
            error("base type with wrong end")
        end
    end
    return r
end

function Parser:read_a_key_value_pair()
    local key = self:read_a_key()
    self:skip_space()
    if self.current_char ~= ":" then
        error("miss \":\"")
        return
    end
    self:get_next_char() -- 跳过 :
    self:skip_space()
    local value = self:read_a_value()
    self:skip_space()
    return key, value
end

function Parser:read_a_json_object()
    self:get_next_char() -- 跳过 {
    self:skip_space()    -- 跳过 { 后的空白
    local len = 0
    local result = {}
    local key_table = {} -- 防止 key 重复
    local key, value = nil, nil
    local current_char = self.current_char
    while true do
        if current_char == '"' then
            key, value = self:read_a_key_value_pair()
            if key_table[key] then
                error("duplicate key")
            else
                key_table[key] = true
                result[key] = value
                self:skip_space()
                len = len + 1
            end
        elseif current_char == "," then
            self:get_next_char() -- 跳过 ,
            self:skip_space()
            if self.current_char ~= "\"" then
                error(", must follw a \" in a json object")
            end
        elseif current_char == "}" or current_char == "" then
            break
        else
            error("wrong json object")
        end
        current_char = self.current_char
    end
    self:get_next_char() -- 跳过 }
    self:skip_space()    -- 跳过文件结束空白
    if self.current_char == "," then
        self:get_next_char()
    end
    local mt = {
        is_array = false,
        len = len
    }
    setmetatable(result, mt)
    return result
end

function Parser:skip_space()
    while space[self.current_char] do
        self:get_next_char()
    end
end

function Parser:parser(root, json_string)
    self.json_string = json_string
    self:get_next_char() -- 读取第一个符
    self:skip_space()    -- 跳过文件开头空白
    local current_char = self.current_char

    if current_char == "{" then
        root = self:read_a_json_object()
    elseif current_char == "[" then
        root = self:read_an_array()
    elseif current_char == '"' then
        root = self:read_a_string()
    else
        root = self:read_a_base_type()
    end
    self:skip_space() -- 跳过文件结束空白
    if self.current_char ~= "" then
        error("has redendent words")
    end
    return root
end

return function(json_string)
    local JSON = {
        root = {},
    }
    setmetatable(JSON, { __index = Parser })
    local s, r = xpcall(Parser.parser, function(error_msg)
        print(debug.traceback(error_msg))
    end, Parser, JSON.root, json_string)
    if s then
        return r
    else
        return nil
    end
end
