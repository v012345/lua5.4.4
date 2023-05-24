local JParser = {
    file = nil,
    char_pointer = 1,
    stream = nil,
    stream_length = 0,
    current_char = nil,
    result = nil,

}
local TokenType = {
    NULL = 1,
    STRING = 2,
    NUMBER = 3,
    INTEGER = 4,
    TRUE = 5,
    FALSE = 6,
}
function JParser:open(file_path)
    local f = io.open(file_path, "r")
    if f then
        self.file = f
        self.stream = f:read("a")
        f:close()
        self.stream_length = #self.stream
        return true, ""
    else
        return false, "can't open file : " .. tostring(file_path)
    end
end

function JParser:get_a_valid_char()
    while not self:is_reach_end_of_stream() do
        if self:is_space(self.current_char) then
            self:get_next_char()
        else
            return self.current_char
        end
    end
    return nil
end

function JParser:get_next_char()
    if self:is_reach_end_of_stream() then
        self.current_char = nil
        return nil
    end
    local b = string.byte(self.stream, self.char_pointer, self.char_pointer)
    self.char_pointer = self.char_pointer + 1
    self.current_char = string.char(b)
    return self.current_char
end

function JParser:can_escape(char)
    if char == "\\" then
        return "\\"
    elseif char == "\"" then
        return "\""
    elseif char == "/" then
        return "/"
    elseif char == "r" then
        return "\r"
    elseif char == "n" then
        return "\n"
    elseif char == "t" then
        return "\t"
    elseif char == "b" then
        return "\b"
    elseif char == "f" then
        return "\f"
    end
    return false
end

function JParser:read_a_string()
    -- debug.sethook(function(a, b)
    --     print(a, b)
    -- end, "l", 0)
    local s = {}
    local char = self:get_next_char()

    while char and char ~= '"' do
        if char == "\\" then
            char = self:get_next_char() -- 跳过第一个 "\"
            local escape_char = self:can_escape(char)
            -- print(escape_char)
            if not escape_char then
                error(tostring(char) .. " can't escape")
            else
                -- print(escape_char)
                s[#s + 1] = escape_char
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

--- 键里不允许转义
function JParser:read_a_key()
    return self:read_a_string()
end

function JParser:read_a_value()
    local value = nil
    if self.current_char == "\"" then
        value = self:read_a_string()
    elseif self.current_char == "[" then
        value = self:read_an_array()
    elseif self.current_char == "{" then
        value = self:read_a_json_object()
    else
        value = self:read_a_base_type()
    end
    return value
end

function JParser:read_an_array()
    self:get_next_char() -- 跳过 [
    self:skip_space()    -- 跳过 [ 后的空白
    local result = {}
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
    local result = {}
    local key_table = {} -- 防止 key 重复
    local key, value = nil, nil
    while self.current_char do
        if self.current_char == '"' then
            key, value = self:read_a_key_value_pair()
            if key then
                if key_table[key] then
                    error("duplicate key")
                else
                    key_table[key] = true
                    result[key] = value
                end
            else
                error("invalid key")
            end
        elseif self:is_space(self.current_char) then
            self:get_next_char()
        elseif self.current_char == "}" then
            break
        elseif self.current_char == "," then
            self:get_next_char() -- 跳过 ,
            self:skip_space()
            if self.current_char ~= "\"" then
                error(", must follw a \" in a json object")
            end
        else
            print(self.current_char)
            error("wrong json object")
        end
    end
    self:get_next_char() -- 跳过 {
    self:skip_space()    -- 跳过文件结束空白
    if self.current_char and self.current_char == "," then
        self:get_next_char()
    end
    return result
end

function JParser:read_root_json_object()
    self:skip_space() -- 跳过文件开头空白

    while self.current_char do
        if self.current_char == "{" then
            self.result = self:read_a_json_object()
        elseif self.current_char == "[" then
            self.result = self:read_an_array()
        elseif self.current_char == '"' then
            self.result = self:read_a_string()
        elseif self:is_space(self.current_char) then
            self:get_next_char()
        else
            self.result = self:read_a_base_type()
        end
    end
    self:skip_space() -- 跳过文件结束空白
    self:get_next_char()
    if self.current_char then
        error("has redendent words")
    end
    return self.result
end

function JParser:is_reach_end_of_stream()
    return self.char_pointer > self.stream_length
end

function JParser:skip_space()
    while self:is_space(self.current_char) do
        if self:is_reach_end_of_stream() then
            return
        else
            self:get_next_char()
        end
    end
end

function JParser:get_first_valid_char()
    local position = 1
    local char = nil
    while position <= self.stream_length do
        char = string.char(string.byte(self.stream, position, position))
        if not self:is_space(char) then
            self.char_pointer = position
            return char
        else
            position = position + 1
        end
    end
end

function JParser:get_a_char() -- 没有实现 uft-8
    if self.char_pointer > self.stream_length then
        return true, ""
    end
    local b = string.byte(self.stream, self.char_pointer, self.char_pointer)
    self.char_pointer = self.char_pointer + 1
    self.current_char = string.char(b)
    return false, self.current_char
end

function JParser:next()

end

function JParser:dump()
    if self.stream then
        local f = io.open("C:\\Users\\Meteor\\Desktop\\o.txt", "w")
        if f then
            f:write(self.stream)
            f:close()
        end
    end
end

function JParser:is_space(c)
    if c == "\t" then
        return true
    elseif c == "\n" then
        return true
    elseif c == " " then
        return true
    elseif c == "\f" then
        return true
    elseif c == "\v" then
        return true
    elseif c == nil then
        return true
    end
    return false
end

-- local function aaa()
--     print(".........日jj")
--     error("ji")
-- end
-- xpcall(aaa, function(a, b)
--     print(a, b)
-- end)
function JParser:parser()
    if self.stream then
        return xpcall(self.read_root_json_object, function(error_msg)
            print(error_msg)
        end, self)
    end
    return nil
end

return JParser
