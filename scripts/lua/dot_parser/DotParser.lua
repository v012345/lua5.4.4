local InputStream = require "utils.InputStream"
local FA_State = require "compiler.FA_State"
---@type function, function
local _, FA_State_Matrix_Entry = table.unpack((require "compiler.FA_State_Matrix"))
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

---comment
---@param this DotParser
---@param what string
function mt.skip(this, what)
    for i = 1, #what, 1 do
        this.stream:checkAndNext(string.sub(what, i, i))
    end
end

---@param this DotParser
---@param FA FA
function mt.parser_main_body(this, FA)
    this.stream:checkAndNext("{")
    this.stream:skip_space()
    while this.stream.current_char ~= "}" do
        local token = this:read_a_token()
        if token == "node" then
            this.stream:checkAndNext("[")
            if this:read_a_token() ~= "shape" then
                error("node must have a shap attributte")
            end
            this:skip("= ")
            local circle_type = this:read_a_token()
            this:skip(";];")
            if circle_type == "doublecircle" then
                this:parser_initial_and_final_states(FA)
            elseif circle_type == "circle" then
                this:parser_states_matrix(FA)
            else
                error("node shape must be doublecircle or circle")
            end
        elseif token == "rankdir" then
            this:skip("= ")
            this:read_a_token()
            this.stream:checkAndNext(";")
            this.stream:skip_space()
        else
            print(token)
            error("can only deal with node and rankdir")
        end
    end
    this.stream:skip_space()
    this.stream:checkAndNext("}")
    this.stream:skip_space()
    if not this.stream.is_end then
        error("dot file must end with }")
    end
end

---comment
---@param this DotParser
---@param FA FA
function mt.parser_states_matrix(this, FA)
    repeat
        this.stream:skip_space()
        local from = this:read_a_token()
        this:skip("->")
        this.stream:skip_space()
        local to = this:read_a_token()
        this.stream:checkAndNext("[")
        if this:read_a_token() ~= "label" then
            error("state must have a label")
        end
        this:skip("= ")
        local label = this:read_a_string()
        this:skip(";];")
        this.stream:skip_space()
        FA:addEntry(FA_State_Matrix_Entry(from, label, to))
    until this.stream.current_char == "n" or this.stream.current_char == "}"
end

---comment
---@param this DotParser
---@return string
function mt.read_a_string(this)
    local escape = {
        ["\\"] = "\\",
        ["\""] = "\"",
        ["/"] = "/",
        ["r"] = "\r",
        ["f"] = "\f",
        ["n"] = "\n",
        ["t"] = "\t",
        ["b"] = "\b",
    }
    local s = {}
    if this.stream.current_char ~= '"' then
        error("string must start with \"")
    else
        this.stream:next()
    end
    while this.stream.current_char ~= '"' do
        if this.stream.current_char == "\\" then
            this.stream:next()

            local escape_char = escape[this.stream.current_char]
            if escape_char then
                s[#s + 1] = escape_char
                this.stream:next()
            else
                error(this.stream.current_char .. " can't escape")
            end
        else
            s[#s + 1] = this.stream.current_char
            this.stream:next()
        end
    end
    this:skip("\"")
    return table.concat(s)
end

---comment
---@param this DotParser
---@param FA FA
function mt.parser_initial_and_final_states(this, FA)
    repeat
        this.stream:skip_space()
        local state = this:read_a_token()
        this.stream:checkAndNext("[")
        if this:read_a_token() ~= "color" then
            error("state must have a color")
        end
        this:skip("= ")
        local color = this:read_a_token()
        this:skip(";];")
        if color == "green" then
            FA:addInitialStates(FA_State(state))
        elseif color == "red" then
            FA:addFinalStates(FA_State(state))
        elseif color == "yellow" then
            FA:addInitialStates(FA_State(state))
            FA:addFinalStates(FA_State(state))
        else
            error("must be green red or yellow")
        end
        this.stream:skip_space()
    until this.stream.current_char == "n" or this.stream.current_char == "}"
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
