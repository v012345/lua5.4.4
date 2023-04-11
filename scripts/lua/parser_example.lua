local i = 1

while i <= 5 do
    if i % 2 == 0 then
        print("Even number: " .. i)
        goto loop_start
    end

    print("Odd number: " .. i)

    ::loop_start::
    i = i + 1
end

print("end")