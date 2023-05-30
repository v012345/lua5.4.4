local Parser = {}
local space = {
    [" "] = " ",
    ["\t"] = "\t",
    ["\n"] = "\n",
    ["\f"] = "\f",
    ["\v"] = "\v",
}
local char_pointer = 1
function Parser:parser(root, xml_string)
    char_pointer = 1
    self.xml_string = xml_string
    local current_char = self:get_next_char()
    while true do
        if space[current_char] then
            current_char = self:get_next_char()
        elseif current_char == "<" then
            self:get_next_char() -- 跳过 <
            root[#root + 1] = self:parser_a_node()
        else
            break
        end

        current_char = self:get_next_char()
    end
    return root
end

function Parser:parser_a_node()
    local node = {
        name = nil,
        attributes = {},
        children = {},
    }
    node.name = self:parser_a_name()

    local current_char = self:skip_space()
    while current_char do
        if current_char == "<" then
            self:get_next_char()
            current_char = self:skip_space()

            if current_char == "/" then
                self:get_next_char()
                if node.name ~= self:parser_a_name() then
                    error("don't close tag")
                end
                self:skip_space()
                self:get_next_char()
                return node
            else
                node.children[#node.children + 1] = self:parser_a_node()
            end
        elseif current_char == "/" then
            self:get_next_char()
            current_char = self:skip_space()
            if current_char == ">" then
                self:get_next_char() -- 跳过 >
                return node
            else
                error(current_char)
            end
        elseif space[current_char] then
            current_char = self:skip_space()
        elseif current_char == ">" then
            current_char = self:get_next_char()
        else
            local key, value = self:parser_a_key_value_pair()
            if key then
                node.attributes[key] = value
            else
                error("miss key")
            end
        end
        current_char = self.current_char
    end
end

function Parser:parser_a_key_value_pair()
    local key = self:parser_a_name()
    local current_char = self:skip_space()
    if current_char ~= "=" then
        error("miss =")
    end
    self:get_next_char()
    local value = self:parser_a_string()
    return key, value
end

function Parser:parser_a_string()
    local current_char = self:skip_space()
    if current_char == "\"" then
        current_char = self:get_next_char() -- 跳过 "
        local s = {}
        while current_char do
            if current_char == "\"" then
                break
            end
            s[#s + 1] = current_char
            current_char = self:get_next_char()
        end
        self:get_next_char() -- 跳过 "
        return table.concat(s)
    else
        error("miss \"")
    end
end

function Parser:skip_space()
    local current_char = self.current_char
    local get_next_char = self.get_next_char
    while space[current_char] do
        current_char = get_next_char(self)
    end
    return current_char
end

function Parser:parser_a_name()
    local current_char = self:skip_space()
    local s = {}
    while current_char do
        if space[current_char] or current_char == ">" or current_char == "=" then
            return table.concat(s)
        end
        s[#s + 1] = current_char
        current_char = self:get_next_char()
    end
    if #s == 0 then
        error("no name")
    end
end

function Parser:get_next_char()
    local _char_pointer = char_pointer
    self.current_char = string.sub(self.xml_string, _char_pointer, _char_pointer)
    _char_pointer = _char_pointer + 1
    char_pointer = _char_pointer
    return self.current_char
end

return function(xml_string)
    local XML = {
        root = {},
    }
    setmetatable(XML, { __index = Parser })
    local s, r = xpcall(Parser.parser, function(error_msg)
        print(debug.traceback(error_msg))
    end, Parser, XML.root, xml_string)
    if s then
        return r
    else
        return nil
    end
end
