local InputStream = require "utils.InputStream"
---@class DotParser
local mt = {}

---comment
---@param this DotParser
---@param FA FA
function mt.parser(this, FA)
    this.stream:skip_space()
    this:parser_name(FA)
    this:parser_main_body(FA)
end

---@param this DotParser
---@param FA FA
function mt.parser_main_body(this, FA)
    this.stream:checkAndNext("{")
    this.stream:skip_space()
    while this.stream.current_char ~= "}" do
        local token = this:read_a_token()
        if token == "node" then
            this.stream:checkAndNext("]")
            if this:read_a_token() ~= "shape" then
                error("node must have a shap attributte")
            end
            this.stream:skip_space()
            this.stream:checkAndNext("=")
            this.stream:skip_space()
            local circle_type = this:read_a_token()
            this.stream:checkAndNext(";")
            this.stream:skip_space()
            this.stream:checkAndNext("]")
            this.stream:skip_space()
            this.stream:checkAndNext(";")
            this.stream:skip_space()

            if circle_type == "doublecircle" then
                this:parser_initial_and_final_states(FA)
            elseif circle_type == "circle" then
            else
                error("node shape must be doublecircle or circle")
            end
        elseif token == "rankdir" then
            this.stream:skip_space()
            this.stream:checkAndNext("=")
            this.stream:skip_space()
            this:read_a_token()
            this.stream:checkAndNext(";")
            this.stream:skip_space()
        else
            error("can only deal with node and rankdir")
        end
    end
    this.stream:skip_space()
    if not this.stream.is_end then
        error("dot file must end with }")
    end
end

---comment
---@param this DotParser
---@param FA FA
function mt.parser_initial_and_final_states(this, FA)
    repeat
        local state = this:read_a_token()
    until state ~= "node"
end

---@param this DotParser
function mt.read_a_token(this)
    local t = {}
    while
        not this.stream:is_space() and
        string.match(this.stream.current_char, "[A-Za-z0-9_]")
    do
        t[#t + 1] = this.stream.current_char
        this.stream:next()
    end
    this.stream:skip_space()
    return table.concat(t)
end

---@param this DotParser
---@param FA FA
function mt.parser_name(this, FA)
    if this:read_a_token() ~= "digraph" then
        error("not a dot file")
    end
    local name = this:read_a_token()
    if #name <= 0 then
        error("must have a name")
    end
    FA:setName(name)
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
