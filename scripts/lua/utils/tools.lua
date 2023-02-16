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

function GetFilesInfoInDirectoryRecursivelyMultiThreads(path)
    local tExcludeFile = {
        [".vscode"] = true,
        [".vs"] = true,
        [".svn"] = true,
        [".git"] = true,
        ["imports"] = true,
    }
    local info = {};
    local function recursive(folder)
        local files = GetFilesTypeInDirectory(folder)

        for file, is_directory in pairs(files) do
            if not tExcludeFile[file] then
                local path = table.concat({ folder, file }, "/")
                if is_directory then
                    recursive(path)
                else
                    info[#info + 1] = path
                end
            end
        end
    end
    recursive(path)

    return GetFilesMd5(info)
end

function GetFilesInfoInDirectoryRecursively(path)
    local tExcludeFile = {
        [".vscode"] = true,
        [".vs"] = true,
        [".svn"] = true,
        [".git"] = true,
    }
    local info = {};
    local function recursive(folder)
        local files = GetFilesInfoInDirectory(folder)
        for _, file in ipairs(files) do
            if not tExcludeFile[file.filename] then
                if file.is_directory then
                    recursive(folder .. "/" .. file.filename)
                else
                    print(string.format("collecting %s info", file.filename))
                    info[folder .. "/" .. file.filename] = file
                end
            end
        end
    end
    recursive(path)
    return info
end

function GetFilesOfDirectoryRecursively(path)
    local tExcludeFile = {
        [".vscode"] = true,
        [".vs"] = true,
        [".svn"] = true,
        [".git"] = true,
    }
    local info = {};
    local function recursive(folder)
        local files = GetFilesTypeInDirectory(folder)
        for file, isDirectory in pairs(files) do
            if not tExcludeFile[file] then
                if isDirectory then
                    recursive(folder .. "/" .. file)
                else
                    --print(file)
                    info[#info + 1] = folder .. "/" .. file
                end
            end
        end
    end
    recursive(path)
    return info
end

---comment
---@param file string
---@param config table
---@return boolean
function WriteConfigTableToFile(file, config)
    if type(config) ~= "table" then
        return false
    end
    local function dumpTable(t)
        if type(t) == 'table' then
            local s = '{'
            for k, v in pairs(t) do
                if type(k) == "number" then
                    s = s .. '[' .. k .. '] = ' .. dumpTable(v) .. ','
                else
                    s = s .. '["' .. k .. '"] = ' .. dumpTable(v) .. ','
                end
            end
            return s .. '}'
        elseif type(t) == "string" then
            return string.format('"%s"', t)
        elseif type(t) == "function" then
            -- config 里不应该有 function
            -- os.exit()
            return string.format('"%s"', t)
        else
            return tostring(t)
        end
    end
    local file = io.open(file, "w")
    if file then
        file:write("local config = ")
        print("writing.....")
        file:write(dumpTable(config))
        file:write("return config")
        print("writed")
        file:close()
        return true
    end
    return false
end
