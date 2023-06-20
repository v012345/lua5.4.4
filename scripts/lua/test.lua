---@diagnostic disable-next-line
function main()
    require "clua"
    require "lparser"
    require "lzio"
    ---@type Zio
    local z = new(Zio)
    local firstchar = zgetc(z)
    luaY_parser(nil, z, nil, nil, "test.lua", firstchar)
end

xpcall(main, function(msg)
    print(msg)
end)
