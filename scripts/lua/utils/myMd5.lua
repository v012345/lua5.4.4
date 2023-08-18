local file = io.open("main.lua", "rb") or error("can't read")
local content = file:read("a")
file:close()

-- 原始长度
local len = #content * 8
print("original len ", len .. " bit")

local function get448(len)
    local m = len % 512
    local append = 512
    if m < 448 then
        append = 448 - m
    elseif m == 448 then
    else
        append = 512 - m + 448
    end
    return append
end
local app1 = get448(len)
if app1 / 8 ~= math.tointeger(app1 / 8) then
    error("allin")
end
local t = { string.char(0x80) }
for i = 2, math.tointeger(app1 / 8) do
    t[i] = string.char(0)
end
content = content .. table.concat(t)
print(#content)
print((#content * 8) % 512)
local mask = {
    0x000000FF,
    0x0000FF00,
    0x00FF0000,
    0xFF000000,
}
local r = {}
for i = 1, 4, 1 do
    local sub_mask = mask[i]
    r[#r + 1] = len & sub_mask
end
local r1 = {}
for i = 1, 4, 1 do
    r1[i] = string.char(r[i] >> ((i - 1) * 8))
end
content = content .. table.concat(r1)
print("ok")
print(#content)
print((#content * 8) % 512)
-- local x = string.pack("B", 1)
-- print(x)
