xpcall(function()
    debug.sethook(function(a, b, c)
        -- print(a, b, c)
    end, "l", 1)
    local FileReader = require "scripts.FileReader"
    local CSV = require "scripts.CSV"
    -- local stream = FileReader("C:\\Users\\Meteor\\Desktop\\trans-client.csv")
    local csv_table = CSV("C:\\Users\\Meteor\\Desktop\\trans-client.csv")
    

    -- while not stream.is_end do
    --     print(stream:check_next("我"), stream:next(), stream.line_number, stream.char_index)
    -- end
end, function(msg)
    print(msg)
end)
