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

---@param this FA_Lable_Lex
---@param what string
function mt.checkAndNext(this, what)
    if this.current_char == what then
        return this:next()
    else
        error("next char is not " .. what)
    end
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
