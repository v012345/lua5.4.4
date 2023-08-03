local luafile = "./clua.lua"

require "bytedump"
local function html_body(file)
    local function div_code(file, codes)
        file:write('<div class="code-container container">')
        local r = Bytedump:dump(codes)
        for i, code in ipairs(r) do
            file:write('<div class="code">')
            file:write(code)
            file:write('</div>')
        end
        file:write('</div>')
    end

    local function div_k(file, const)
        file:write('<div class="const-container container">')
        for i, k in ipairs(const) do
            file:write('<div class="const">')
            file:write((string.gsub(k, string.char(60), "&lt")))
            file:write('</div>')
        end
        file:write('</div>')
    end

    local function div_upvalue(file, upvalues)
        file:write('<div class="upvalue-container container">')
        for i, upvalue in ipairs(upvalues) do
            file:write('<div class="upvalue">')
            file:write(tostring(upvalue.name))
            file:write('</div>')
        end
        file:write('</div>')
    end

    local function div_locvar(file, locvars)
        file:write('<div class="locvar-container container">')
        for i, locvar in ipairs(locvars) do
            file:write('<div class="locvar">')
            file:write(tostring(locvar))
            file:write('</div>')
        end
        file:write('</div>')
    end

    local p1 = luac(luafile)
    local function div_closure(p, output)
        file:write('<div class="closure-container container">')
        div_locvar(output, p.locvars)
        div_k(output, p.k)
        div_upvalue(output, p.upvalues)
        div_code(output, p.code)
        file:write('<div class="sub-closure-container container">')
        for key, value in pairs(p.p) do
            div_closure(value, output)
        end
        file:write('</div>')
        file:write('</div>')
    end
    div_closure(p1, file)
end

local function html(file, h5)
    file:write("<!DOCTYPE html>")
    local function tofile(file, tag)
        if tag.name then
            file:write("<")
            file:write(tag.name)
            file:write(" ")
            for key, value in pairs(tag.attributes) do
                if value then
                    file:write(string.format("%s=\"%s\" ", key, value))
                else
                    file:write(key)
                    file:write(" ")
                end
            end
            file:write(">")
            for _, sub_tag in ipairs(tag.children) do
                tofile(file, sub_tag)
            end
            if tag.attributes["id"] == "app" then
                html_body(file)
            end
            file:write(string.format("</%s>", tag.name))
        else
            file:write(tag.children[1])
        end
    end
    tofile(file, h5[1])
end

local function json(file, lua_table)
    local function tofile(file, lua_table)
        file:write("{")
        file:write('"locvars":[')

        if #lua_table.locvars > 0 then
            local t = {}
            for index, value in ipairs(lua_table.locvars) do
                t[#t + 1] = string.format('"%s"', value)
            end
            local s = table.concat(t, ",")
            file:write(s)
        end
        file:write('],')
        file:write('"k":[')
        if #lua_table.k > 0 then
            local t = {}
            for index, value in ipairs(lua_table.k) do
                t[#t + 1] = string.format('%s', string.format("%q", value))
            end
            local s = table.concat(t, ",")
            file:write(s)
        end
        file:write('],')
        file:write('"upvalues":[')
        if #lua_table.upvalues > 0 then
            local t = {}
            for index, value in ipairs(lua_table.upvalues) do
                file:write('{')
                local t = {}
                for k, v in pairs(value) do
                    t[#t + 1] = string.format('"%s"', k)
                    t[#t + 1] = ":"
                    t[#t + 1] = string.format('"%s"', v)
                    t[#t + 1] = ","
                end
                t[#t] = ""
                local s = table.concat(t)
                file:write(s)
                file:write('}')
                if index < #lua_table.upvalues then
                    file:write(',')
                end
            end
        end
        file:write('],')
        file:write('"code":[')
        local r = Bytedump:dump(lua_table.code)
        for i, code in ipairs(r) do
            file:write('"')
            file:write(code)
            file:write('"')
            if i < #r then
                file:write(',')
            end
        end
        file:write('],')
        file:write('"p":[')
        if #lua_table.p > 0 then
            for index, value in ipairs(lua_table.p) do
                tofile(file, value)
                if index < #lua_table.p then
                    file:write(",")
                end
            end
        end
        file:write(']')
        file:write("}")
    end
    tofile(file, lua_table)
end

xpcall(function()
    local h5 = require "utils.html2table"
    local lh5 = h5("./h5.html")
    local o = io.open("./dump.html", "w") or error()
    html(o, lh5)
    o:close()

    local h5js = io.open("./h5.json", "w") or error()
    json(h5js, luac(luafile))
    h5js:close()
    print("done")
end, function(msg)
    print(msg)
end)
