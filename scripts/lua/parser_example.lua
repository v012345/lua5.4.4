require("bytedump")
for i = 1, 10, 2 do
    local j = i
    if j > 5 then
        break
    end
    i = i + 10
    i = i - 20
    i = i - 20.3
end
local i = 1
if i == 2 then
    print(i)
end

Bytedump:dump(GetOpCodes())
