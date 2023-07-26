-- require "dot_parser.parser"
---@diagnostic disable-next-line
local a = 1
local b = 2
local c = a > b
if a > b then
    a = b
elseif a > b then
    b = a
else
    a = b
end
