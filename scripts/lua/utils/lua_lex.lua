local Lex = {
    file = nil,
    linenumber = 0,
    position = 1,
    linechars = 0,
    current = "",
    stream = nil,
    type = {
        reserved = 0,
        string = 1,
        number = 2,
        other = 5,
    }
}
local END_OF_FILE = "\n==END_OF_FILE==\n"

function Lex:load(file_path)
    local file = io.open(file_path, "r")
    if file then
        self.file = file
        Lex:get_a_char()
    else
        error("Lex can't open " .. file_path)
    end
end

function Lex:look_next_char()
    return string.sub(self.stream, self.position + 1, self.position + 1)
end

function Lex:get_a_char()
    if self.linechars <= 0 then
        self.stream = self.file:read("L")
        if not self.stream then
            self.current = END_OF_FILE
            return END_OF_FILE
        end
        self.linechars = #self.stream
        self.position = 1
    end
    local p = self.position
    local c = string.sub(self.stream, p, p)
    self.position = p + 1
    self.linechars = self.linechars - 1
    self.current = c
    return c
end

function Lex:skip_the_line()
    self.linechars = 0
end

function Lex:test()
    -- local c = self:next()
    -- while c.token ~= END_OF_FILE do
    --     print(self.linenumber)
    --     c = self:next()
    -- end
end

function Lex:next()
    local c = self.current
    while c ~= END_OF_FILE do
        if c == "\n" or c == "\r" then
            self.linenumber = self.linenumber + 1
            c = self:get_a_char()
        elseif c == " " or c == "\f" or c == "\t" or c == "\v" then
            c = self:get_a_char()
        elseif c == "-" then
            c = self:get_a_char()
            if c ~= "-" then
                return self:token("-")
            end
            self:skip_the_line() -- 只支持单行注释
            c = self:get_a_char()
        elseif c == "[" then
            c = self:get_a_char()
            return self:token("[")
        elseif c == "=" then
            c = self:get_a_char()
            if c == "=" then
                c = self:get_a_char()
                return self:token("==")
            else
                return self:token("=")
            end
        elseif c == "<" then
            c = self:get_a_char()
            if c == "=" then
                c = self:get_a_char()
                return self:token("<=")
            elseif c == "<" then
                c = self:get_a_char()
                return self:token("<<")
            else
                return self:token("<")
            end
        elseif c == ">" then
            c = self:get_a_char()
            if c == "=" then
                c = self:get_a_char()
                return self:token(">=")
            elseif c == ">" then
                c = self:get_a_char()
                return self:token(">>")
            else
                return self:token(">")
            end
        elseif c == "/" then
            c = self:get_a_char()
            if c == "/" then
                c = self:get_a_char()
                return self:token("//")
            else
                return self:token("/")
            end
        elseif c == "~" then
            c = self:get_a_char()
            if c == "=" then
                c = self:get_a_char()
                return self:token("~=")
            else
                return self:token("~")
            end
        elseif c == ":" then
            c = self:get_a_char()
            if c == ":" then
                c = self:get_a_char()
                return self:token("::")
            else
                return self:token(":")
            end
        elseif c == "\"" or c == "'" then
            return {
                token = self.type.string,
                value = self:read_string(c)
            }
        elseif c == "." then
            c = self:get_a_char()
            if c == "." then
                c = self:get_a_char()
                if c == "." then
                    c = self:get_a_char()
                    return self:token("...")
                else
                    return self:token("..")
                end
            else
                return self:token(".") -- 不支持 .122 这么定义小数
            end
        elseif c == "0" or c == "1" or c == "2" or c == "3" or c == "4" or c == "5" or c == "6" or c == "7" or c == "8" or c == "9" then
            return {
                token = self.type.number,
                value = self:read_number()
            }
        else
            local b = string.byte(c)
            if b >= 65 and b <= 90 or b >= 97 and b <= 122 then
                local type, value = self:read_name()
                if type then
                    return {
                        token = self.type.reserved,
                        value = value
                    }
                else
                    return {
                        token = self.type.other,
                        value = value
                    }
                end
            else
                local t = c
                c = self:get_a_char()
                return self:token(t)
            end
        end
    end
    return self:token(c)
end

function Lex:token(c)
    return {
        token = c,
        value = c
    }
end

function Lex:read_number() -- 只支持 10 进制小数
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
    local c = self.current
    local t = {}
    while m[c] do
        t[#t + 1] = c
        c = self:get_a_char()
    end
    return tonumber(table.concat(t))
end

function Lex:read_string(d) -- 不允许转义字符出现, 不想写
    local c = self:get_a_char()
    local t = {}
    while c ~= d do
        t[#t + 1] = c
        c = self:get_a_char()
    end
    c = self:get_a_char()
    return table.concat(t)
end

function Lex:read_name(d) -- 用空格分隔
    local c = self.current
    local t = {}
    local m = {
        ["and"] = 0,
        ["break"] = 0,
        ["do"] = 0,
        ["else"] = 0,
        ["elseif"] = 0,
        ["end"] = 0,
        ["false"] = 0,
        ["for"] = 0,
        ["function"] = 0,
        ["goto"] = 0,
        ["if"] = 0,
        ["in"] = 0,
        ["local"] = 0,
        ["nil"] = 0,
        ["not"] = 0,
        ["or"] = 0,
        ["repeat"] = 0,
        ["return"] = 0,
        ["then"] = 0,
        ["true"] = 0,
        ["until"] = 0,
        ["while"] = 0,
    }
    while c ~= " " and c ~= END_OF_FILE do
        if string.match(c, "[0-9a-zA-Z_]") then
            t[#t + 1] = c
            c = self:get_a_char()
        else
            break
        end
    end
    local name = table.concat(t)

    return m[name], name
end

function Lex:run()
    -- local l = self.linenumber
end

-- function Lex:lookahead()

-- end

return Lex
