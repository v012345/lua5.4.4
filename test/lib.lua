Global = {}
function Global.log_2(x)
    local log_2 = {
        0, 1, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 4, 4, 4, 4, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 6, 6, 6, 6, 6, 6,
        6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6,
        6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
        7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
        7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8,
        8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8,
        8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8,
        8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8,
        8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8,
        8, 8, 8, 8, 8, 8, 8, 8, 8, 8 };
    local l = 0
    x = x - 1
    while x >= 256 do
        l = l + 8;
        x = x >> 8;
    end

    return l + log_2[x];
end

function Global.wchar_to_utf8(ws)
    local unicode = 0
    local str = {}
    for index, value in ipairs(ws) do
        if 0xDC00 <= value and value <= 0xDFFF then
            -- Skip Low Surrogate
        else
            unicode = value
            if 0xD800 <= value and value <= 0xDBFF then
                local high = value - 0xD800
                local low = ws[index + 1] - 0xDC00
                unicode = (high << 10) + low
            end
            -- print(index, unicode)
            if unicode < 256 then -- ascii
                str[#str + 1] = unicode
            else
                local size = unicode;
                size = (size >> 1) | size;
                size = (size >> 2) | size;
                size = (size >> 4) | size;
                size = (size >> 8) | size;
                size = (size >> 16) | size;
                size = (size >> 32) | size;
                size = size + 1;
                -- print(Global.log_2(size))
                print(size, Global.log_2(size))
            end
        end
    end
end
