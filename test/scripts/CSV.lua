local function CSV(path)
    local res = {}
    local parser = {
        stream = (require "scripts.FileReader")(path),
    }
    function parser:parser_a_quotation_string()
        self.stream:next() -- 跳过第一个 "
        local str = {}
        while not self.stream.is_end do
            if self.stream.current == '"' then
                if self.stream:check_next('"') then -- 就是一个 "
                    self.stream:next()
                    str[#str + 1] = self.stream.current;
                elseif self.stream:check_next(',') or self.stream:check_next('\n') then
                    self.stream:next()
                    return table.concat(str) --完事了
                else
                    -- 出事了
                    error(string.format("line_number %s, chat_at %s illegal item", self.stream.line_number,
                        self.stream.char_index))
                end
            else
                str[#str + 1] = self.stream.current;
            end
            self.stream:next()
        end
    end

    function parser:parser_a_normal_string()
        local str = {}
        while true do
            if self.stream.current == ',' or self.stream.current == "\n" then
                return table.concat(str) --完事了
            else
                str[#str + 1] = self.stream.current;
            end
            self.stream:next()
        end
    end

    local t = { {} }
    parser.stream:next() -- 读第一个字符
    while not parser.stream.is_end do
        if parser.stream.current == '"' then
            if not t[#t] then
                t[#t] = {}
            end
            local col = t[#t]
            col[#col + 1] = parser:parser_a_quotation_string()
        elseif parser.stream.current == ',' then
            if parser.stream:check_next(',') or parser.stream:check_next('\n') then
                if not t[#t] then
                    t[#t] = {}
                end
                local col = t[#t]
                col[#col + 1] = ""
            end
            parser.stream:next() --跳过第一个 ,
        elseif parser.stream.current == '\n' then
            t[#t + 1] = {}
            if parser.stream:check_next(',')then
                local col = t[#t]
                col[#col + 1] = ""
            end
            parser.stream:next()
        else
            if not t[#t] then
                t[#t] = {}
            end
            local col = t[#t]
            col[#col + 1] = parser:parser_a_normal_string()
        end
    end
    t[#t] = nil
    res.table = t
    function res:write_to(where)
        local file = io.open(where, "w") or error("can't open " .. where)
        for _, row in ipairs(self.table) do
            local row_content = {}
            for _, cell in ipairs(row) do
                row_content[#row_content + 1] = string.format('"%s"', string.gsub(cell, '"', '""'))
            end
            file:write(table.concat(row_content, ","))
            file:write("\n")
        end
        file:close()
    end

    return res
end

return CSV
