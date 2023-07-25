-- require "dot_parser.parser"
---@diagnostic disable-next-line
local a = false
local b = 1
local c = 1
local d = 1
local e = 1
local f = 1
local x = a and b and c and c and d and e and f
print(type(x))
