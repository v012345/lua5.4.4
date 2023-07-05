---@class FA_Lable_Lex
local mt = {}

---@param this FA_Lable_Lex
---@return string|nil
function mt.next(this)
    if this.current_position > this.content_len then
        this.current_char = nil
        this.is_end = true
    else
        local current_position = this.current_position
        this.current_position = this.current_position + 1
        this.current_char = string.sub(this.content, current_position, current_position)
    end
    return this.current_char
end

---comment
---@param this FA_Lable_Lex
---@param what string
---@return boolean
function mt.peekOne(this, what)
    local position = this.current_position + 1
    if string.sub(this.content, position, position) == what then
        return true
    end
    return false
end

---已经路过
---@param this FA_Lable_Lex
---@return FA_Lable_Lex
function mt.getNewLabel(this)
    this:next() -- 跳过 (
    local level = 0
    local t = {}
    while
        this.current_char ~= ")" and
        level == 0
    do
        if this.current_char == "(" then level = level + 1 end
        if this.current_char == ")" then level = level - 1 end
        if not this.current_char then error("miss )") end
        t[#t + 1] = this.current_char
        this:next()
    end
    this:next() -- 跳过 )
    return (require "compiler.FA_Lable_Lex")(table.concat(t))
end

---已经路过
---@param this FA_Lable_Lex
---@return FA_Lable_Lex
function mt.createNewLabelWithRest(this)
    local r = (require "compiler.FA_Lable_Lex")(string.sub(this.content, this.current_position, this.content_len))
    this.current_position = this.content_len
    while this.current_char do
        this:next()
    end
    return r
end

---@param this FA_Lable_Lex
---@param what string
function mt.checkAndNext(this, what)
    if this.current_char == what then
        return this:next()
    else
        error("next char is not " .. what)
    end
end

---@param this FA_Lable_Lex
---@return string
function mt.readAlias(this)
    local t = {}
    if this.current_char ~= "$" then
        error("alias must start with $")
    end
    t[#t + 1] = this.current_char
    repeat
        t[#t + 1] = this:next()
        if not this.current_char then
            error("alias must end with $")
        end
    until this.current_char == "$"
    this:next()
    return table.concat(t)
end

---@param label string
---@return FA_Lable_Lex
return function(label)
    ---@class FA_Lable_Lex
    ---@field private content string
    ---@field current_char string|nil
    ---@field private current_position integer
    local FA_Lable_Lex = {
        content = "",
        current_char = "",
        current_position = 1,
        content_len = 0,
        is_end = false,
    }
    FA_Lable_Lex.content = label
    FA_Lable_Lex.content_len = #FA_Lable_Lex.content
    setmetatable(FA_Lable_Lex, {
        __index = mt
    })
    return FA_Lable_Lex
end
