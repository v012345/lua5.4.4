Global = {}
function Global.log_2(x)
    local log_2 = {
        1, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 4, 4, 4, 4, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 6, 6, 6, 6, 6, 6,
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
                local high = ((value - 0xD800) << 10) + 0x10000
                local low = ws[index + 1] - 0xDC00
                unicode = high + low
            end
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
                local bits = Global.log_2(size)
                if size ~= unicode then
                    bits = bits - 1
                end
                local x = math.ceil((bits - 6) / 5) + 1
                local head = 0
                for i = 1, x, 1 do
                    head = (head << 1) + 1
                end
                for i = 1, 8 - x, 1 do
                    head = (head << 1)
                end
                head = head + (unicode >> (6 * (x - 1)))
                str[#str + 1] = head
                for i = x - 1, 1, -1 do
                    local body = 0x80
                    local mask = 0x3f << ((i - 1) * 6)
                    body = body + ((unicode & mask) >> ((i - 1) * 6))
                    str[#str + 1] = body
                end
            end
        end
    end
    return str
end
