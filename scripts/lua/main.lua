-- require "dot_parser.parser"
---@diagnostic disable-next-line
local a = 1
local b = 2
if a then
    a = b
elseif b then
    b = a
else
    a = b
end
