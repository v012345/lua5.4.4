local InputStream = require "utils.InputStream"
---@class DotParser
local mt = {}

---comment
---@param this DotParser
---@param FA FA
function mt.parser(this, FA)
    this.stream:skip_space()
    this:parser_name(FA)
end

---@param this DotParser
function mt.read_a_token(this)
    local t = {}
    while
        not this.stream:is_space() and
        string.match(this.stream.current_char, "[A-Za-z0-9]")
    do
        t[#t + 1] = this.stream.current_char
        this.stream:next()
    end
    return table.concat(t)
end

---@param this DotParser
---@param FA FA
function mt.parser_name(this, FA)
    print(this:read_a_token())
end

---@param path_file string
---@param FA FA
return function(path_file, FA)
    if getmetatable(FA) ~= "FA" then
        error("arg #2 must be a FA")
    end
    ---@class DotParser
    local DotParser = {
        stream = InputStream(path_file),
    }
    setmetatable(DotParser, {
        __index = mt
    })
    DotParser:parser(FA)
end
