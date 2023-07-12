local function get_png_size(path)
    local png_file = io.open(path, "rb") or error("can't read " .. path)
    local data = png_file:read(64) -- 读入 64 bytes 就可以包含头部了
    png_file:close()

    -- 保证png至少有37个字节，因为包含文件头等起码就超过这个数字了
    if #data < 37 then
        error("file is to small " .. #data .. "bytes")
    end

    -- 文件头的相关信息请百度
    local png_header_info = {
        0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, -- PNG头部署名域，表示这是一个PNG图片
        0x00, 0x00, 0x00, 0x0d,                         --描述IHDR头部的大小
        0x49, 0x48, 0x44, 0x52,                         --是Chunk Type Code, 这里Chunk Type Code=IHDR
    }
    for i = 1, #png_header_info do
        if (string.byte(data, i) ~= png_header_info[i]) then
            error("can't parser " .. path)
        end
    end


    local sizeData = string.sub(data, 17, 24)
    local hexbyte = {}
    for i = 1, 8 do
        hexbyte[i] = string.byte(sizeData, i)
    end

    local width = tonumber(string.format("0x%x%x%x%x", hexbyte[1], hexbyte[2], hexbyte[3], hexbyte[4]))
    local height = tonumber(string.format("0x%x%x%x%x", hexbyte[5], hexbyte[6], hexbyte[7], hexbyte[8]))

    return width, height
end

return get_png_size
