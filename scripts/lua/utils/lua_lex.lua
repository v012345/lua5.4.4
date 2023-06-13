local Lex = {
    file = nil
}

function Lex:load(file_path)
    local file = io.open(file_path, "r")
    if file then
        print("ok_ffi")
        self.file = file
    else
        error("Lex can't open " .. file_path)
    end
end

return Lex
