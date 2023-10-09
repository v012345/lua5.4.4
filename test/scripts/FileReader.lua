---只支持 uft-8 格式的文本文件
---@param path string
local function FileReader(path)
    local file = io.open(path, "r") or error("can't open" .. path)
    local content = file:read("a")
    if #content > 3 then
        -- check bom
        local bom = string.format("%x%x%x", string.byte(content, 1, 3))
        if string.lower(bom) == "efbbbf" then
            content = string.sub(content, 4, #content)
        end
    end

    file:close()
    ---@class stream
    ---@field line_number integer cur 所在的行号
    ---@field char_index integer cur 所在的行的字符号
    ---@field is_end boolean 是否要文件结尾
    ---@field current string 当前字符
    ---@field private content string
    ---@field private length integer
    local stream = {
        content = content,
        length = #content,
        position = 0,
        line_number = 1,
        char_index = 0,
        current = "",
        is_end = false,
    }
    function stream:next()
        if not self.is_end then
            self.position = self.position + 1
            if self.position > self.length then
                self.current = ""
                self.is_end = true
            else
                self.current = self:get_a_char()
                if self.current == "\n" then
                    self.char_index = 0
                    self.line_number = self.line_number + 1
                else
                    self.char_index = self.char_index + 1
                end
            end
        end
        return self.current
    end

    ---看下一个字符是不是 what
    ---@param what string
    ---@return boolean
    function stream:check_next(what)
        if self.position >= self.length then
            return false -- 结束符和谁也不等
        end
        local next_position = self.position + 1
        local head = string.byte(self.content, next_position, next_position)
        if (head & 0x80) ~= 0 then
            local length = stream:get_char_lenght(head) - 1
            local char = string.sub(self.content, next_position, next_position + length)
            return char == what
        else
            return string.char(head) == what
        end
    end
    ---@private
    function stream:get_a_char()
        local head = string.byte(self.content, self.position, self.position)
        if (head & 0x80) ~= 0 then
            local length = stream:get_char_lenght(head) - 1
            local char = string.sub(self.content, self.position, self.position + length)
            self.position = self.position + length
            return char
        else
            return string.char(head)
        end
    end

    ---@private
    function stream:get_char_lenght(head)
        if ((head & 0xc0) ~ 0x80) == 0 then
            error("not a utf-8 head")
        end
        if (head & 0x80) == 0 then
            return 1
        elseif (head & 0x20) == 0 then
            return 2
        elseif (head & 0x10) == 0 then
            return 3
        elseif (head & 0x08) == 0 then
            return 4
        elseif (head & 0x04) == 0 then
            return 5
        elseif (head & 0x02) == 0 then
            return 6
        elseif (head & 0x01) == 0 then
            return 7
        end
    end

    return stream
end

return FileReader
