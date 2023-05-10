require("bytedump")

local file = io.open("aaa.pbm", "w")
io.output(file)
local function disk(cx, cy, r)
    return function(x, y)
        return (x - cx) ^ 2 + (y - cy) ^ 2 <= r ^ 2
    end
end

local function plot(r, M, N)
    io.write("P1\n", M, " ", N, "\n")
    for i = 1, N, 1 do
        local y = (N - i * 2) / N
        for j = 1, M, 1 do
            local x = (j * 2 - M) / M
            io.write(r(x, y) and "1" or "0")
        end
        io.write("\n")
    end
end
plot(disk(0, 0, 1), 500, 500)
io.close(file)
Bytedump:dump(GetOpCodes())
