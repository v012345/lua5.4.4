-- require "dot_parser.parser"
---@diagnostic disable-next-line
local a = 1
local b = 2
local c = a and b
if a and b then
    a = b
elseif a > b then
    b = a
else
    a = b
end
