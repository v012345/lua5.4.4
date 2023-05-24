local JParser = {
    file = nil,
    pointer = 1,
    stream = nil
}

function JParser:open(file_path)
    local f = io.open(file_path, "r")
    if f then
        self.file = f
        self.stream = f:read("a")
        return true, self.stream
    else
        return false, "can't open file : " .. tostring(file_path)
    end
end

function JParser:next()
    self.pointer = self.pointer + 1
    return string.byte(self.stream, self.pointer - 1, 1)
end

function JParser:output()
    local t = {}
    -- for i = 1, 999, 1 do
    --     t[#t + 1] = self:next()
    -- end
    print(table.concat(t))
end

function JParser:dump()
    if self.stream then
        local f = io.open("C:\\Users\\Meteor\\Desktop\\o.txt", "w")
        if f then
            f:write(self.stream)
        end
    end
end

return JParser
