Global = {}
function Global.wchar_to_utf8(ws)
    local unicode = 0
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
            print(index, unicode)
        end
    end
end
