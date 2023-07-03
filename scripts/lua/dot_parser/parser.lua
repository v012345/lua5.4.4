local file = io.open("./dot/NDF.dot", "r") or error("can't open file")
local content = file:read("a")
file:close()

local function get_next_char()
    local _char_pointer = char_pointer
    current_char = string.sub(dot_string, _char_pointer, _char_pointer)
    _char_pointer = _char_pointer + 1
    char_pointer = _char_pointer
    return current_char
end
