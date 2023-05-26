local JParser = {
    char_pointer = 1,
    json_string = nil,
    json_string_length = 0,
    current_char = nil,
    result = nil,
}
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

function JParser:escape_string(str)
    local start = 1
    local o = {}
    local char_byte = string.byte(str, start, start)
    while char_byte do
        local len = self:utf8_byte_num(char_byte)
        local char = string.sub(str, start, start + len - 1)
        if escape_r[char] then
            o[#o + 1] = escape_r[char]
        else
            o[#o + 1] = char
        end
        start = start + len
        char_byte = string.byte(str, start, start)
    end
    return table.concat(o)
end

function JParser:is_space(c)
    return space[c]
end

function JParser:can_escape(c)
    return escape[c]
end

function JParser:utf8_byte_num(c)
    if c & 0x80 == 0 then
        return 1
    elseif c & 0xd0 == 0xd0 then
        return 2
    elseif c & 0xe0 == 0xe0 then
        return 3
    elseif c & 0xf0 == 0xf0 then
        return 4
    elseif c & 0xf8 == 0xf8 then
        return 5
    else
        error("need extending")
    end
end

function JParser:get_next_char()
    local start = self.char_pointer
    local char_byte = string.byte(self.json_string, start, start)
    if char_byte then
        local len = self:utf8_byte_num(char_byte)
        self.current_char = string.sub(self.json_string, start, start + len - 1)
        self.char_pointer = start + len
        return self.current_char
    end
    self.current_char = false
    return false
end

function JParser:read_a_string()
    local s = {}
    local char = self:get_next_char()

    while char and char ~= '"' do
        if char == "\\" then
            char = self:get_next_char() -- 跳过第一个 "\"
            local escape_char = escape[char]
            if escape_char then
                s[#s + 1] = escape_char
            else
                error(tostring(char) .. " can't escape")
            end
        else
            s[#s + 1] = char
        end
        char = self:get_next_char()
    end
    if char ~= '"' then
        error("string unexcepted end")
    end
    self:get_next_char() --跳过结尾 "
    return table.concat(s)
end

function JParser:read_a_key()
    return self:read_a_string()
end

function JParser:read_a_value()
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

function JParser:read_an_array()
    self:get_next_char() -- 跳过 [
    self:skip_space()    -- 跳过 [ 后的空白
    local mt = {
        is_array = true
    }
    local result = {}
    setmetatable(result, mt)
    while self.current_char do
        if self.current_char == '"' then
            result[#result + 1] = self:read_a_string()
        elseif self:is_space(self.current_char) then
            self:get_next_char()
        elseif self.current_char == "{" then
            result[#result + 1] = self:read_a_json_object()
        elseif self.current_char == "," then
            self:get_next_char() -- 跳过 ,
            self:skip_space()
            if self.current_char == "]" then
                error("the last element has a , follow")
            end
        elseif self.current_char == "]" then
            break
        elseif self.current_char == "[" then
            result[#result + 1] = self:read_an_array()
        else
            result[#result + 1] = self:read_a_base_type()
        end
    end
    self:get_next_char() -- 跳过 ]
    self:skip_space()    -- 跳过文件结束空白
    if self.current_char and self.current_char == "," then
        self:get_next_char()
    end
    return result
end

function JParser:read_a_base_type()
    local s = {}
    local r = nil
    while self.current_char and string.find(self.current_char, "[0-9aeflnrstu%.%-]") do
        s[#s + 1] = self.current_char
        self:get_next_char()
    end
    local token = table.concat(s)
    if token == "true" then
        r = true
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

function JParser:read_a_key_value_pair()
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

function JParser:read_a_json_object()
    self:get_next_char() -- 跳过 {
    self:skip_space()    -- 跳过 { 后的空白
    local len = 0
    local result = {}
    local key_table = {} -- 防止 key 重复
    local key, value = nil, nil
    local current_char = self.current_char
    while current_char do
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
        elseif current_char == "}" then
            break
        else
            error("wrong json object")
        end
        current_char = self.current_char
    end
    self:get_next_char() -- 跳过 }
    self:skip_space()    -- 跳过文件结束空白
    if self.current_char and self.current_char == "," then
        self:get_next_char()
    end
    local mt = {
        is_array = false,
        len = len
    }
    setmetatable(result, mt)
    return result
end

function JParser:start()
    self.json_string_length = #self.json_string
    self:get_next_char() -- 读取第一个符
    self:skip_space()    -- 跳过文件开头空白
    local current_char = self.current_char

    if current_char == "{" then
        self.result = self:read_a_json_object()
    elseif current_char == "[" then
        self.result = self:read_an_array()
    elseif current_char == '"' then
        self.result = self:read_a_string()
    else
        self.result = self:read_a_base_type()
    end
    self:skip_space() -- 跳过文件结束空白
    if self.current_char then
        error("has redendent words")
    end
    return self.result
end

function JParser:is_reach_end_of_stream()
    return self.char_pointer > self.json_string_length
end

function JParser:skip_space()
    while space[self.current_char] do
        self:get_next_char()
    end
end

function JParser:dump_raw(file_path)
    if self.json_string then
        local f = io.open(file_path, "w")
        if f then
            f:write(self.json_string)
            f:close()
        end
    end
end

function JParser:dump(file_path)
    if self.result then
        local f = io.open(file_path, "w")
        if f then
            local function table_to_string(t)
                if type(t) == 'table' then
                    local mt = getmetatable(t)
                    if mt then
                        if mt.is_array then
                            local len = #t

                            local s = '['
                            for k, v in ipairs(t) do
                                s = s .. table_to_string(v)
                                if k ~= len then
                                    s = s .. ","
                                end
                            end
                            return s .. '] '
                        else
                            local i = 1
                            local s = '{ '
                            for k, v in pairs(t) do
                                s = s .. table_to_string(k) .. ': ' .. table_to_string(v)
                                if i < mt.len then
                                    i = i + 1
                                    s = s .. ', '
                                end
                            end
                            return s .. '} '
                        end
                    else
                        error("not a lua json")
                    end
                elseif type(t) == "string" then
                    return string.format('"%s"', self:escape_string(t))
                else
                    local base_type = tostring(t)
                    if base_type == "nil" then
                        base_type = "null"
                    end
                    return base_type
                end
            end
            f:write(table_to_string(self.result))
            f:close()
        end
    end
end

function JParser:parser(path_or_string)
    local f = io.open(path_or_string, "r")
    if f then
        self.json_string = f:read("a")
        f:close()
    else
        self.json_string = path_or_string
    end
    return xpcall(self.start, function(error_msg)
        print(error_msg)
    end, self)
end

return JParser
