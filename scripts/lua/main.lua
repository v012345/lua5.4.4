local function html_css(file)

end

local function html_head(file)
    file:write([[
        <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>lua</title>
        <script src="https://unpkg.com/vue@3/dist/vue.global.js"></script>
        <style>
    ]])
    html_css(file)
    file:write([[
        </style>
        </head>
    ]])
end

local function html_body(file)
    local function div_code(file, codes)
        file:write('<div class="code-container container">')
        for i, code in ipairs(codes) do
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
            file:write(k)
            file:write('</div>')
        end
        file:write('</div>')
    end

    local function div_upvalue(file, upvalues)
        file:write('<div class="upvalue-container container">')
        for i, upvalue in ipairs(upvalues) do
            file:write('<div class="upvalue">')
            file:write(tostring(upvalue))
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

    local p1 = Compile("./clua.lua")
    local function div_closure(p, output)
        file:write('<div class="closure-container container">')
        div_locvar(output, p.locvars)
        div_k(output, p.k)
        div_upvalue(output, p.upvalues)
        div_code(output, p.code)
        for key, value in pairs(p.p) do
            div_closure(value, output)
        end
        file:write('</div>')
    end
    file:write("<body>")
    file:write('<div id="app">')
    file:write('{{ message }}')
    div_closure(p1, file)
    file:write('</div>')
    file:write("</body>")
end

local function html_script(file)
    file:write("<script>")
    file:write([[
        const { createApp, ref } = Vue

        createApp({
          setup() {
            const message = ref('Top level function!')
            return {
              message
            }
          }
        }).mount('#app')
    ]])
    file:write("</script>")
end

local function html(file)
    file:write([[
        <!DOCTYPE html>
        <html lang="en">
    ]])
    html_head(file)
    html_body(file)
    html_script(file)
    file:write("</html>")
end

xpcall(function()
    local o = io.open("./dump.html", "w") or error()
    html(o)
    o:close()
end, function(msg)
    print(msg)
end)
