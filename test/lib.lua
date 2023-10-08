Global = {}
function Global.wchar_to_utf8(ws)
    for index, value in ipairs(ws) do
        print(index, string.format("%x", value))
    end
end
