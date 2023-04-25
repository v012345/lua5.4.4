require("bytedump")
for i = 1, 10, 2 do
    local j = i
    if j > 5 then
        break
    end
end

Bytedump:dump(GetOpCodes())
