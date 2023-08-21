---@class CSV
local mt = {}

---comment
---@return Node
function mt:parser()
    self:get_next_char()
    local t = { {} }
    while self.current ~= "" do
        if self.current == '"' then
            local col = t[#t]
            col[#col + 1] = self:parser_a_string()
        elseif self.current == ',' then
            self:get_next_char()
        elseif self.current == '\n' then
            t[#t + 1] = {}
            self:get_next_char()
        end
    end
    t[#t] = nil
    return t
end

---comment
---@return string
function mt:parser_a_string()
    if self.current == '"' then
        self:get_next_char() -- 跳过 "
        local s = {}
        while self.current ~= '"' do
            s[#s + 1] = self.current
            self:get_next_char()
        end
        self:get_next_char() -- 跳过 "
        return table.concat(s)
    else
        error('miss "')
    end
end

---comment
---@return string
function mt:get_next_char()
    self.position = self.position + 1
    self.current = string.sub(self.stream, self.position, self.position)
    return self.current
end

---comment
---@param file_path string
---@return Node
return function(file_path)
    local file = io.open(file_path, "r") or error("can't open " .. file_path)
    local content = file:read("a")
    file:close()
    ---@class CSV
    local CSV = {
        stream = content,
        position = 0,
        current = ""
    }
    setmetatable(CSV, { __index = mt })
    local _, r = xpcall(CSV.parser, function(msg)
        print(msg)
    end, CSV)
    return r
end
