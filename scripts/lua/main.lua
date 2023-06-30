package.path =
    table.concat({
        package.path, ";",
        (debug.getinfo(1, "S").short_src:gsub("[^\\/]+.lua$", "?.lua", 1))
    })
print(package.path)
require "utils.set"
