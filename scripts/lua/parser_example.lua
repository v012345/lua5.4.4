require("bytedump")

x = 1
x = x * 20
x = x / 20
x = x + 20
x = x - 20
x = x >> 20
x = x << 20
x = x % 20
x = x ~ 20
if x <= 10 then
    x = nil
end


Bytedump:dump(GetOpCodes())
