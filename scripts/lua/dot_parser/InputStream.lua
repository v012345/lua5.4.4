---@class InputStream
local mt = {}

---@param this InputStream
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

---@param this InputStream
---@param what string
function mt.checkAndNext(this, what)
    if this:peek() == what then
        return this:next()
    else
        error("next char is not " .. what)
    end
end

---@param this InputStream
---@param num integer|nil
function mt.peek(this, num)
    num = num or 1
    return string.sub(this.content, this.current_position, this.current_position + num)
end

---@param path_file string
---@return InputStream
return function(path_file)
    ---@class InputStream
    ---@field private content string
    ---@field current_char string|nil
    ---@field private current_position integer
    local InputStream = {
        content = "",
        current_char = "",
        current_position = 1,
        content_len = 0,
        is_end = false,
    }
    local file = io.open(path_file, "r") or error(string.format("can't open %s", path_file), 1)
    InputStream.content = file:read("a")
    file:close()
    InputStream.content_len = #InputStream.content
    setmetatable(InputStream, {
        __index = mt
    })
    return InputStream
end
