local p1 = Compile("./clua.lua")


local function printP(p)
    local vars = p.locvars
    -- print(1)
    for index, value in ipairs(vars) do
        print(value)
    end
    local vars1 = p.upvalues
    for index, value in ipairs(vars1) do
        print(index)
        for index, value in pairs(value) do
            print(index, value)
        end
    end
    for key, value in pairs(p.p) do
        printP(value)
    end
end
printP(p1)
