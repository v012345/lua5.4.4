local JParser = {
    file = nil
}

function JParser:open(file_path)
    local f = io.open(file_path, "r")
    if f then
        self.file = f
        return true, f
    else
        return false, "can't open file : " .. tostring(file_path)
    end
end

function JParser:dump()
    if self.file then
        print(self.file:read("a"))
    end
end

return JParser
