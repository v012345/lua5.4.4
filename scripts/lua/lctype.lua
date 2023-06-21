---@diagnostic disable-next-line
function lislalpha(c)
    if 65 <= c and c <= 90 then
        return true
    elseif c == 95 then
        return true
    elseif 97 <= c and c <= 122 then
        return true
    else
        return false
    end
end

---@diagnostic disable-next-line
function lisdigit(c)
    if 48 <= c and c <= 57 then
        return true
    else
        return false
    end
end

---@diagnostic disable-next-line
function lislalnum(c)
    if lislalpha(c) then
        return true
    else
        return lisdigit(c)
    end
end
