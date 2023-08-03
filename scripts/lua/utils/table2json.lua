return function(lt)
    local r = {}
    local function toJson(t)
        local typ = type(t)
        if typ == "nil" then
            r[#r + 1] = "null"
        elseif typ == "number" then
            r[#r + 1] = tostring(t)
        elseif typ == "boolean" then
            r[#r + 1] = tostring(t)
        elseif typ == "string" then
            r[#r + 1] = string.format("%q", t)
        elseif typ == "table" then
            r[#r + 1] = "{"
            for key, value in pairs(t) do
                if type(key) == "number" then
                    r[#r + 1] = "\""
                    r[#r + 1] = key
                    r[#r + 1] = "\""
                else
                    r[#r + 1] = string.format("%q", key)
                end
                r[#r + 1] = ":"
                toJson(value)
                r[#r + 1] = ","
            end
            if next(t) then
                table.remove(r)
            end
            r[#r + 1] = "}"
        else
            error("can't convert to json")
        end
    end
    toJson(lt)
    for i = 1, 10, 1 do
        print(r[i])
    end
    return table.concat(r)
end
