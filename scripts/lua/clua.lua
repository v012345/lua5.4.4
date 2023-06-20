---@diagnostic disable-next-line
function new(struct)
    if type(struct) ~= "table" then
        error("must a table")
    end
    ---@diagnostic disable-next-line
    local function clone(struct)
        local r = {}
        for key, value in pairs(struct) do
            if type(value) == "table" then
                r[key] = clone(value)
            else
                r[key] = value
            end
        end
        return r
    end
    return clone(struct)
end
