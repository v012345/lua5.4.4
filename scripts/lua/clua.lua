---comment
---@param struct any
---@return table
---@diagnostic disable-next-line

goto acc
local a = 1
local b = 1
local d = 1


function c()
    a = 1
    print(1)
end

function new1(struct)
    if type(struct) ~= "table" then
        error(debug.traceback("must a table given a " .. type(struct)))
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

function new(struct)
    if type(struct) ~= "table" then
        error(debug.traceback("must a table given a " .. type(struct)))
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

::acc::