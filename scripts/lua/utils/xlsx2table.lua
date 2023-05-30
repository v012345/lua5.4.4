local Parser = {
    pointer = 1,
    current_byte = nil,
}
local space = {
    [" "] = " ",
    ["\t"] = "\t",
    ["\n"] = "\n",
    ["\f"] = "\f",
    ["\v"] = "\v",
}

function Parser:parser(xls_string)
    self.pointer = 1
end

function Parser:get_next_byte()
    local _pointer = self.pointer
    self.current_byte = string.sub(self.json_string, _pointer, _pointer)
    _pointer = _pointer + 1
    self.pointer = _pointer
    return self.current_byte
end

return function(xls_string)
    local _, xsl = xpcall(Parser.parser, function(error_msg)
        print(debug.traceback(error_msg))
    end, Parser, xls_string)
    return xsl
end
