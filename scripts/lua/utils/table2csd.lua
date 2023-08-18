---comment
---@param node Node
local function table2csd(node, to)
    local file = io.open(to, "w") or error("can't open " .. to)
    ---comment
    ---@param n Node
    ---@param f file*
    local function node2csd(n, f)
        f:write("<", n.name, " ")
        for k, v in pairs(n.attributes) do
            f:write(k, "=", '"', v, '" ')
        end
        if #n.children == 0 then
            f:write("/>\n")
        else
            f:write(">\n")
            for _, child in ipairs(n.children) do
                node2csd(child, f)
            end
            f:write("</", n.name, ">\n")
        end
    end
    node2csd(node, file)
    file:close()
end

return table2csd
