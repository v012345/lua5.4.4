local function html(file, h5)
    file:write("<!DOCTYPE html>")
    local function tofile(file, tag)
        print(tag.name)
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
            file:write(string.format("</%s>", tag.name))
        else
            file:write(tag.children[1])
        end
    end
    tofile(file, h5[1])
end

xpcall(function()
    local h5 = require "utils.html2table"
    local lh5 = h5("./h5.html")
    local o = io.open("./dump.html", "w") or error()
    html(o, lh5)
    o:close()
end, function(msg)
    print(msg)
end)
