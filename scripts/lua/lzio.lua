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
        return string.byte(z.data, z.p, z.p)
    end
end
