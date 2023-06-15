---@class LexState
local LexState = {
    line_number = 0,
    char_pointer = 1,
    char_position = 1,
    stream_len = 0,
    ---@type string|number
    current_char = "",
    stream = nil,
    type = {
        reserved = 1,
        string = 2,
        number = 3,
        symbol = 4,
        name = 5,
        other = 6,
        end_of_file = -1,
    },
    token = {
        type = 1,
        value = 1,
    },
    ahead_token = {
        type = 1,
        value = 1,
    },
}

function LexState:load(file_path)
    local file = io.open(file_path, "r")
    if file then
        self.stream = file:read("a")
        file:close()
        self.stream_len = #self.stream
        self.ahead_token = nil
        self.token = nil
        self.current_char = nil
        LexState:get_a_char()
    else
        error("LexState can't open " .. file_path)
    end
end

---@private
function LexState:get_a_char()
    if self.char_pointer >= self.stream_len then
        self.current_char = self.type.end_of_file
        return self.type.end_of_file
    end
    local p = self.char_pointer
    local c = string.sub(self.stream, p, p)
    self.char_pointer = p + 1
    self.current_char = c
    return c
end

function LexState:skip_the_line()
    while self.current_char ~= "\n" and self.current_char ~= self.type.end_of_file do
        self:get_a_char()
    end
end

function LexState:set_token(type, value)
    self.token = {
        type = type,
        value = value,
    }
    return self.token
end

function LexState:test()
    local c = self:get_next_token()
    local l = self.line_number
    while c.type ~= self.type.end_of_file do
        if self.line_number > l then
            l = self.line_number
            io.write("\n")
        end
        io.write(" ")
        io.write(c.value, c.type)
        c = self:get_next_token()
    end
end

function LexState:get_next_token()
    local c = self.current_char
    while self.current_char ~= self.type.end_of_file do
        c = self.current_char
        if c == "\n" or c == "\r" then
            self.line_number = self.line_number + 1
            c = self:get_a_char()
        elseif c == " " or c == "\f" or c == "\t" or c == "\v" then
            c = self:get_a_char()
        elseif c == "-" then
            c = self:get_a_char()
            if c ~= "-" then
                return self:set_token(self.type.other, "-")
            end
            self:skip_the_line() -- 只支持单行注释
        elseif c == "[" then
            c = self:get_a_char()
            return self:set_token(self.type.other, "[")
        elseif c == "=" then
            c = self:get_a_char()
            if c == "=" then
                c = self:get_a_char()
                return self:set_token(self.type.other, "==")
            else
                return self:set_token(self.type.other, "=")
            end
        elseif c == "<" then
            c = self:get_a_char()
            if c == "=" then
                c = self:get_a_char()
                return self:set_token(self.type.other, "<=")
            elseif c == "<" then
                c = self:get_a_char()
                return self:set_token(self.type.other, "<<")
            else
                return self:set_token(self.type.other, "<")
            end
        elseif c == ">" then
            c = self:get_a_char()
            if c == "=" then
                c = self:get_a_char()
                return self:set_token(self.type.other, ">=")
            elseif c == ">" then
                c = self:get_a_char()
                return self:set_token(self.type.other, ">>")
            else
                return self:set_token(self.type.other, ">")
            end
        elseif c == "/" then
            c = self:get_a_char()
            if c == "/" then
                c = self:get_a_char()
                return self:set_token(self.type.other, "//")
            else
                return self:set_token(self.type.other, "/")
            end
        elseif c == "~" then
            c = self:get_a_char()
            if c == "=" then
                c = self:get_a_char()
                return self:set_token(self.type.other, "~=")
            else
                return self:set_token(self.type.other, "~")
            end
        elseif c == ":" then
            c = self:get_a_char()
            if c == ":" then
                c = self:get_a_char()
                return self:set_token(self.type.other, "::")
            else
                return self:set_token(self.type.other, ":")
            end
        elseif c == "\"" or c == "'" then
            return self:set_token(self.type.string, self:read_string(c))
        elseif c == "." then
            c = self:get_a_char()
            if c == "." then
                c = self:get_a_char()
                if c == "." then
                    c = self:get_a_char()
                    return self:set_token(self.type.other, "...")
                else
                    return self:set_token(self.type.other, "..")
                end
            else
                return self:set_token(self.type.other, ".") -- 不支持 .122 这么定义小数
            end
        elseif c == "0" or c == "1" or c == "2" or c == "3" or c == "4" or c == "5" or c == "6" or c == "7" or c == "8" or c == "9" then
            return self:set_token(self.type.number, self:read_number())
        else
            local b = string.byte(c)
            if b >= 65 and b <= 90 or b >= 97 and b <= 122 then
                local type, value = self:read_name()
                return self:set_token(type, value)
            else
                local t = c
                c = self:get_a_char()
                return self:set_token(self.type.other, t)
            end
        end
    end
    return self:set_token(self.type.end_of_file, self.type.end_of_file)
end

function LexState:read_number() -- 只支持 10 进制小数
    local m = {
        ["0"] = "0",
        ["1"] = "0",
        ["2"] = "0",
        ["3"] = "0",
        ["4"] = "0",
        ["5"] = "0",
        ["6"] = "0",
        ["7"] = "0",
        ["8"] = "0",
        ["9"] = "0",
        ["."] = "0",
    }
    local c = self.current_char
    local t = {}
    while m[c] do
        t[#t + 1] = c
        c = self:get_a_char()
    end
    return tonumber(table.concat(t))
end

function LexState:read_string(d) -- 不允许转义字符出现, 不想写
    local c = self:get_a_char()
    local t = {}
    while c ~= d do
        t[#t + 1] = c
        c = self:get_a_char()
    end
    c = self:get_a_char()
    return table.concat(t)
end

function LexState:read_name(d) -- 用空格分隔
    local c = self.current_char
    local t = {}
    local r = self.type.reserved
    local m = {
        ["and"] = r,
        ["break"] = r,
        ["do"] = r,
        ["else"] = r,
        ["elseif"] = r,
        ["end"] = r,
        ["false"] = r,
        ["for"] = r,
        ["function"] = r,
        ["goto"] = r,
        ["if"] = r,
        ["in"] = r,
        ["local"] = r,
        ["nil"] = r,
        ["not"] = r,
        ["or"] = r,
        ["repeat"] = r,
        ["return"] = r,
        ["then"] = r,
        ["true"] = r,
        ["until"] = r,
        ["while"] = r,
    }
    while c ~= " " and c ~= self.type.end_of_file do
        if string.match(c, "[0-9a-zA-Z_]") then
            t[#t + 1] = c
            c = self:get_a_char()
        else
            break
        end
    end
    local name = table.concat(t)
    if m[name] then
        return m[name], name
    else
        return self.type.name, name
    end
end

function LexState:error(what)
    error(string.format("line:%s, %s", self.line_number, what))
end

function LexState:test_next_token_and_skip(type, value)
    local char_pointer = self.char_pointer
    local current_char = self.current_char
    local line_number = self.line_number
    local token = self:get_next_token()
    if token.type == type and token.value == value then
        return true
    end
    self.char_pointer = char_pointer
    self.current_char = current_char
    self.line_number = line_number
    return false
end

function LexState:test_next_token(type, value)
    local char_pointer = self.char_pointer
    local current_char = self.current_char
    local line_number = self.line_number
    local token = self:get_next_token()
    self.char_pointer = char_pointer
    self.current_char = current_char
    self.line_number = line_number

    if token.type == type and token.value == value then
        return true
    end
    return false
end

return LexState
