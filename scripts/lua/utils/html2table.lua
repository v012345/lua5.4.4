---@class H5
local mt = {}
local space = {
    [" "] = " ",
    ["\t"] = "\t",
    ["\n"] = "\n",
    ["\f"] = "\f",
    ["\v"] = "\v",
}

---解析无名标签
---@return tag
function mt:parser_content()
    ---@type tag
    local tag = {
        name = nil,
        attributes = {},
        children = {}
    }
    local current = self.current
    local s = {}
    while current ~= "" and current ~= "<" do
        s[#s + 1] = current
        current = self:next_char()
    end
    tag.children[#tag.children + 1] = table.concat(s)
    return tag
end

---解析标签的属性
---@param tag tag
function mt:parser_attributes(tag)
    self:skip_space()
    while self.current ~= ">" and self.current ~= "/" do
        local key = self:parser_a_name()
        local current_char = self:skip_space()
        ---@type string|false
        local value = false
        if current_char == "=" then
            self:next_char() -- 跳过 =
            value = self:parser_a_string()
        end
        self:skip_space()
        tag.attributes[key] = value
    end
end

---解析标签的属性值使用
---@return string
function mt:parser_a_string()
    self:skip_space()
    local current = self.current
    if current == "\"" then
        current = self:next_char() -- 跳过 "
        local s = {}
        while current ~= "" do
            if current == "\"" then
                break
            end
            s[#s + 1] = current
            current = self:next_char()
        end
        self:next_char() -- 跳过 "
        return table.concat(s)
    else
        error("miss \"")
    end
end

---解析一个标签的名字
---@return string
function mt:parser_a_name()
    self:skip_space()
    local s = {}
    while self.current ~= "" do
        local current = self.current
        if space[current] or current == ">" or current == "=" or current == "/" then
            break
        end
        s[#s + 1] = current
        self:next_char()
    end
    if #s == 0 then
        error("no name")
    end
    self:skip_space()
    return table.concat(s)
end

---跳过空白字符
---@param self H5
---@return string
function mt.skip_space(self)
    while space[self.current] do
        self:next_char()
    end
    return self.current
end

---输入流的下一个字符
---@param self H5
---@return string
function mt.next_char(self)
    local position = self.position + 1
    self.current = string.sub(self.stream, position, position)
    self.position = position
    return self.current
end

---查看是不是匹配
---@param self H5
---@param what string
---@return boolean
function mt.check(self, what)
    local position = self.position
    return string.sub(self.stream, position, position + #what - 1) == what
end

---comment
---@param self H5
---@param num any
function mt.skip(self, num)
    self.position = self.position + num
    self.current = string.sub(self.stream, self.position, self.position)
    return self.current
end

---解析一个标签
---@return tag
function mt:parser_a_tag()
    ---@class tag
    local tag = {
        name = nil,
        is_close = false,
        attributes = {},
        children = {}
    }
    self:next_char() -- 跳过 <
    if self:skip_space() == "/" then
        self:next_char()
        tag.name = self:parser_a_name()
        self:skip_space()
        self:next_char()
        tag.is_close = true
        return tag
    end

    tag.name = self:parser_a_name()
    self:skip_space()

    self:parser_attributes(tag)

    while true do
        local current = self.current
        if current == "<" then
            local sub_tag = self:parser_a_tag()
            if sub_tag.is_close then -- 自己的闭合标签
                if tag.name ~= sub_tag.name then
                    error("don't close tag")
                end
                return tag
            else
                -- 子标签
                tag.children[#tag.children + 1] = sub_tag
            end
        elseif current == "/" then -- 自闭合标签
            self:next_char()
            current = self:skip_space()
            if current == ">" then
                self:next_char() -- 跳过 >
                return tag
            else
                error("can't close byself")
            end
        elseif current == ">" then -- 有内容, 内容可能还有子标签, 所以内容当无名标签处理
            -- 跳过 >
            self:next_char()
            tag.children[#tag.children + 1] = self:parser_content()
        elseif space[current] then
            self:skip_space()
        end
    end
end

---解析一个 html 文件
---@param self H5
function mt.parser(self)
    self:next_char()  -- 读取第一个字符
    self:skip_space() -- 跳过空白
    local DOCTYPE = "<!DOCTYPE html>"
    if self:check(DOCTYPE) then
        self:skip(#DOCTYPE)
    end
    self:skip_space()
    while true do
        if space[self.current] then
            self:next_char()
        elseif self.current == "<" then
            self.document[#self.document + 1] = self:parser_a_tag()
        else
            -- 到这里就是 "" 空字符串
            break
        end
    end
    -- return root
end

---解析一个 html 文件
---@param html_file_path string
---@return table|nil
return function(html_file_path)
    local file = io.open(html_file_path, "r") or error("can't open " .. html_file_path)
    local stream = file:read("a")
    file:close()

    ---@class H5
    local H5 = {
        stream = stream,
        current = "",
        position = 0,
        document = {},
    }
    setmetatable(H5, { __index = mt })
    if xpcall(H5.parser, function(msg) print(msg) end, H5) then
        return H5.document
    end
end
