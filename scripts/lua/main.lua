local function div_code(file, codes)
    file:write('<div class="code-container">')
    for i, code in ipairs(codes) do
        file:write('<div class="code">')
        file:write(code)
        file:write('</div>')
    end
    file:write('</div>')
end

local function div_k(file, const)
    file:write('<div class="const-container">')
    for i, k in ipairs(const) do
        file:write('<div class="const">')
        file:write(k)
        file:write('</div>')
    end
    file:write('</div>')
end

local function div_upvalue(file, upvalues)
    file:write('<div class="upvalue-container">')
    for i, upvalue in ipairs(upvalues) do
        file:write('<div class="upvalue">')
        file:write(tostring(upvalue))
        file:write('</div>')
    end
    file:write('</div>')
end

xpcall(function()
    local p1 = Compile("./clua.lua")
    require "bytedump"
    local o = io.open("./dump.html", "w") or error()
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

        div_k(output, p.k)
        div_upvalue(output, p.upvalues)
        div_code(output, p.code)
        output:write("p :\n")
        for key, value in pairs(p.p) do
            printP(value, output, tab + 1)
        end
    end
    printP(p1, o, 0)
    o:close()
end, function(msg)
    print(msg)
end)
