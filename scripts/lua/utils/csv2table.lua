---@class CSV
local mt = {}

---comment
---@return Node
function mt:parser()
    self:get_next_char()
    self:skip_space()
    if self.current == "<" then
        self:get_next_char() -- 跳过 <
        return self:parser_a_node()
    else
        error("not a csd file")
    end
end

---comment
---@return Node
function mt:parser_a_node()
    ---@class Node
    local node = {
        name = nil,
        ---@type table<string,string>
        attributes = {},
        ---@type Node[]
        children = {},
        content = ""
    }
    node.name = self:parser_a_name()

    self:skip_space()
    while true do
        self:skip_space()
        if self.current == "<" then
            self:get_next_char()
            self:skip_space()
            if self.current == "/" then
                self:get_next_char()
                if node.name ~= self:parser_a_name() then
                    error("don't close tag " .. node.name)
                end
                self:skip_space()
                self:get_next_char()
                return node
            else
                node.children[#node.children + 1] = self:parser_a_node()
            end
        elseif self.current == "/" then
            self:get_next_char()
            self:skip_space()
            if self.current == ">" then
                self:get_next_char() -- 跳过 >
                return node
            else
                error("miss > after /")
            end
        elseif self.current == ">" then
            self:get_next_char() -- 跳过 >
            node.content = self:parser_content()
        else
            local key, value = self:parser_a_key_value_pair()
            if key then
                node.attributes[key] = value
            else
                error("miss key")
            end
        end
    end
end

---comment
---@return string
function mt:parser_content()
    self:skip_space()
    local s = {}
    while self.current ~= "<" do
        s[#s + 1] = self.current
        self:get_next_char()
    end
    if #s > 0 then
        error("csd can't have content")
    end
    return table.concat(s)
end

---comment
---@return string
---@return string
function mt:parser_a_key_value_pair()
    local key = self:parser_a_name()
    self:skip_space()
    if self.current ~= "=" then
        error("miss =")
    end
    self:get_next_char()
    local value = self:parser_a_string()
    return key, value
end

---comment
---@return string
function mt:parser_a_string()
    self:skip_space()
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
function mt:skip_space()
    local space = {
        [" "] = " ",
        ["\t"] = "\t",
        ["\n"] = "\n",
        ["\f"] = "\f",
        ["\v"] = "\v",
    }
    while space[self.current] do
        self:get_next_char()
    end
    return self.current
end

---comment
---@return string
function mt:parser_a_name()
    self:skip_space()
    local s = {}
    while string.match(self.current, "[a-zA-Z%-]") do
        s[#s + 1] = self.current
        self:get_next_char()
    end
    if #s == 0 then
        error("no name")
    else
        return table.concat(s)
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
