local FileReader = require "scripts.FileReader"
xpcall(function()
    local stream = FileReader("D:\\NightOwlTools\\Lua\\README.md")
    while not stream.is_end do
        print(stream:next(), stream.line_number, stream.char_index)
    end
end, function(msg)
    print(msg)
end)
