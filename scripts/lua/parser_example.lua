local counter, step = 10, 1
counter = 12
step = 6

for index, value in pairs(PrintProtoCode()) do
    print(index)
    for key, value1 in pairs(value) do
        print(key)
        print(value1)
    end
end
