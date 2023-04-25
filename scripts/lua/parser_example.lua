function X()
    Bytedump:dump(GetOpCodes())
    local A = 100
    return A
end

local C = {

}
function C:p()
    self.X = 11
end

require("bytedump")

Bytedump:dump(GetOpCodes())
X()

print("end")

return
