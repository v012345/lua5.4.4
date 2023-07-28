local p1 = Compile("./clua.lua")
require "bytedump"
local o = io.open("./dump.txt", "w") or error()
o:write("top level function: \n")
local function printP(p, output, tab)
    local vars = p.locvars
    output:write(string.rep("\t", tab))
    output:write("vars :\t")
    for _, value in ipairs(vars) do
        output:write(value)
        output:write("\t")
    end
    output:write("\n")
    output:write(string.rep("\t", tab))
    output:write("upvalues :\t")
    local vars1 = p.upvalues
    for _, value in ipairs(vars1) do
        output:write(value.name)
        output:write("\t")
    end
    output:write("\n")
    output:write(string.rep("\t", tab))
    Bytedump:dump(p.code)
    print("--------")
    output:write("p :\n")
    for key, value in pairs(p.p) do
        printP(value, output, tab + 1)
    end
end
printP(p1, o, 0)
o:close()
