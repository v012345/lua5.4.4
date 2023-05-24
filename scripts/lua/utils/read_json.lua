local JParser = {
    file = nil,
    pointer = 1,
    stream = nil,
    strlen = 0
}

function JParser:open(file_path)
    local f = io.open(file_path, "r")
    if f then
        self.file = f
        self.stream = f:read("a")
        self.strlen = #self.stream
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
    for i = 1, self.strlen, 1 do
        local char = string.char(self:next())
        if char ~= "\n" and
            char ~= "\t" and
            char ~= "\v" and
            char ~= " " then
            print(i)
            -- t[#t + 1] = char
        end
    end
    -- print(self.strlen)
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
