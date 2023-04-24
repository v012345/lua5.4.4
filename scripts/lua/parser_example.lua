local counter, step = 10, 1
counter = 12
step = 6

for index, value in pairs(GetOpCodes()) do
    for key, value1 in pairs(value) do
        if type(value1) == "number" then
            print(value1 & 0x7F)
        end
    end
end
