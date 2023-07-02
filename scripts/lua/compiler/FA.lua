
local mt = {}
return function()
    FA = {}
    setmetatable(FA, {
        __index = mt
    })
    return FA
end
