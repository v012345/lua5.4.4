require "llex"

EOZ = -1
---@class Zio
Zio = {
    n = 0,        -- bytes still unread
    p = 0,        -- current position in buffer
    reader = nil, -- reader function
    data = nil,   -- additional data
    L = nil,      -- Lua state (for reader)
};

---@class Mbuffer
Mbuffer = {
    buffer = {},
    n = 0
}

---comment
---@param buff Mbuffer
---@diagnostic disable-next-line
function luaZ_resetbuffer(buff)
    buff.buffer = {}
    buff.n = 0
end

---comment
---@param buff Mbuffer
---@return table
---@diagnostic disable-next-line
function luaZ_buffer(buff)
    return buff.buffer
end

---comment
---@param buff Mbuffer
---@return integer
---@diagnostic disable-next-line
function luaZ_bufflen(buff)
    return buff.n
end

---comment
---@param z Zio
---@return integer
---@diagnostic disable-next-line
function luaZ_fill(z)
    local file = io.open("./test.lua", "r") or error("can't open ./test.lua")
    z.data = file:read("a")
    z.n = #z.data
    z.p = 0
    z.p = z.p + 1
    z.n = z.n - 1
    return string.byte(z.data, z.p, z.p)
end

---comment
---@param z Zio
---@diagnostic disable-next-line
function zgetc(z)
    if z.n <= 0 then
        if z.p > 0 then
            return EOZ
        else
            return luaZ_fill(z)
        end
    else
        z.p = z.p + 1
        z.n = z.n - 1
        return string.byte(z.data, z.p, z.p)
    end
end
