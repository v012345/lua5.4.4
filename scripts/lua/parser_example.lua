local function a()
    local z = 2
    local x = 1
    local y = 2
    local function b()
        x = x + 1
        return x;
    end
    return b
end

local c = a()

print(c())
print(c())
print(c())
