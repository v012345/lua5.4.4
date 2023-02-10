---comment
---@param data any
function PrintTableToJson(data)
    local function dump(t)
        if type(t) == 'table' then
            local i = 1
            local l = 0
            for _, _ in pairs(t) do
                l = l + 1
            end

            local s = '{ '
            for k, v in pairs(t) do
                s = s .. '"' .. k .. '" : ' .. dump(v)
                i = i + 1
                if i <= l then
                    s = s .. ', '
                end
            end
            return s .. '} '
        elseif type(t) == "string" then
            return string.format('"%s"', t)
        elseif type(t) == "function" then
            return string.format('"%s"', t)
        else
            return tostring(t)
        end
    end
    print(dump(data))
end

---comment
---@param file string
---@return any|nil
function GetFileContent(file)
    local f, err = io.open(file, 'r')
    if err then
        error(err)
    end
    local contents = nil;
    if f then
        contents = f:read("*a")
        f:close()
    end
    return contents
end
