local a = { 1, 2, 3, 4, 5, 6, 7, 8, 9 }
print(#a)
a[8] = nil
a[9] = nil
a[1] = nil
print(#a)
a[4] = nil
print(#a)
a[4] = 4
print(#a)
a[5] = nil
print(#a)

local a = { 1, 2, 3, 4, 5, 6, 7, 8, a = "a", [15] = 18 }
print(#a)
-- a.a = nil
a[9] = 9
print(#a)

local a = { 1, 2, 3, 4, 5, 6, 7, 8, a = "a", [16] = 18 }
print(#a)
-- a.a = nil
a[9] = 9
print(#a)

local a = { 1, 2, 3, 4, 5, 6, 7, 8, [17] = 18 }
print(#a)
-- a.a = nil
a[9] = 9
print(#a)
