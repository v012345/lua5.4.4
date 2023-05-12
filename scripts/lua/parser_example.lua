require("bytedump")
function F(x)
    return {
        set = function(y)
            x = y
            local a = 1
            Bytedump:dump(GetOpCodes())
        end,
        get = function()
            do
                Bytedump:dump(GetOpCodes())
                local a = 1
                return x
            end
        end
    }
end

local o = F(10)
o.set(100)
print(o.get())
debug.sethook()
-- local o2 = F(20)
-- print(o1.get(), o2.get())
-- o1.set(100)
-- o2.set(200)
-- print(o1.get(), o2.get())

-- Bytedump:dump(GetOpCodes())
