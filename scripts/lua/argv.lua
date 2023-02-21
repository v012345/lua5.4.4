---命令行参数
argv = {}

function ProcessArgv()
    local t = {}
    for i, v in ipairs(argv) do
        print(v)
        if v == "-b" then
            t["branch"] = argv[i + 1]
        elseif v == "-f" then
            t["from"] = argv[i + 1]
        elseif v == "-t" then
            t["to"] = argv[i + 1]
        elseif v == "-m" then
            t["module"] = argv[i + 1]
        end
    end
    t["parser"] = argv[1]
    argv = t;
end

return
