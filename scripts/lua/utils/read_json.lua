return function(path_or_string)
    local json_string = ""
    local f = io.open(path_or_string, "r")
    if f then
        json_string = f:read("a")
        f:close()
    else
        json_string = path_or_string
    end
    local JParser = {
        char_pointer = 1,
        stream = nil,
        stream_length = 0,
        current_char = nil,
        result = nil,
    }
    function JParser:open(file_path)
        local f = io.open(file_path, "r")
        if f then
            self.stream = f:read("a")
            f:close()
            return self:star()
        end
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
        local s = {}
        local char = self:get_next_char()

        while char and char ~= '"' do
            if char == "\\" then
                char = self:get_next_char() -- 跳过第一个 "\"
                local escape_char = self:can_escape(char)
                if not escape_char then
                    error(tostring(char) .. " can't escape")
                else
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
        local mt = {
            is_array = false
        }

        local result = {}
        setmetatable(result, mt)
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

    function JParser:dump_raw(file_path)
        if self.stream then
            local f = io.open(file_path, "w")
            if f then
                f:write(self.stream)
                f:close()
            end
        end
    end

    function JParser:dump(file_path)
        if self.stream then
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
                                local l = 0
                                for _, _ in pairs(t) do
                                    l = l + 1
                                end

                                local s = '{ '
                                for k, v in pairs(t) do
                                    s = s .. '"' .. k .. '" : ' .. table_to_string(v)
                                    i = i + 1
                                    if i <= l then
                                        s = s .. ', '
                                    end
                                end
                                return s .. '} '
                            end
                        else
                            error("not a lua json")
                        end
                    elseif type(t) == "string" then
                        return string.format('"%s"', t)
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

    function JParser:star()
        self.stream_length = #self.stream
        return xpcall(self.read_root_json_object, function(error_msg)
            print(error_msg)
        end, self)
    end

    function JParser:parser(json_string)
        self.stream = json_string
        return self:star()
    end

    return function()
        return JParser:parser(json_string)
    end
end