xpcall(function()
    local all_langs = { "zhcn", "en", "id", "th", "vi" }
    local root_path = "D:\\Closers.cocos\\resource\\ui\\branches\\dzogame_sea"

    for _, lang in ipairs(all_langs) do
        local plist = string.format("%s\\%s\\Closers_temp_plist.ccs", root_path, lang)
        local game_res = "D:\\Closers.cocos\\client\\branches\\dzogame_sea\\Resources\\res_" .. lang
        local cocos_cmd =
        "\"C:\\Cocos\\Cocos Studio\\Cocos.Tool.exe\" publish -f %s -o %s -s -d Serializer_FlatBuffers"
        print(string.format(cocos_cmd, plist, game_res))
        local exe_cmd = io.popen(string.format(cocos_cmd, plist, game_res)) or error("can't execute " .. cocos_cmd)
        print(exe_cmd:read("a"))
        exe_cmd:close()
    end
    -- debug.sethook(function(a, b, c)
    --     -- print(a, b, c)
    -- end, "l", 1)
    -- local FileReader = require "scripts.FileReader"
    -- local CSV = require "scripts.CSV"
    -- -- local stream = FileReader("D:\\Closers.cocos\\resource\\ui\\branches\\dzogame_sea\\zhcn\\ur-trans.csv")
    -- -- do 00010100000
    -- --     return
    -- -- end
    -- -- local csv_table = CSV("C:\\Users\\Meteor\\Desktop\\trans-client.csv")
    -- local myTran = CSV("D:\\Closers.cocos\\resource\\ui\\branches\\dzogame_sea\\zhcn\\trans.csv")
    -- -- myTran:write_to("C:\\Users\\Meteor\\Desktop\\New folder\\my-trans1.csv")

    -- local urTran = CSV("D:\\Closers.cocos\\resource\\ui\\branches\\dzogame_sea\\zhcn\\ur-trans.csv")
    -- urTran:write_to("C:\\Users\\Meteor\\Desktop\\New folder\\trans-client1.csv")
    -- local myCN = {}
    -- local myCNCSD = {}
    -- for index, value in ipairs(myTran.table) do
    --     myCN[value[1]] = true
    --     myCNCSD[value[6]] = myCNCSD[value[6]] or {}
    --     local csds = myCNCSD[value[6]]
    --     csds[#csds + 1] = index
    -- end
    -- local urCN = {}
    -- local idontknow = {}
    -- local misscn = {}
    -- local OKcn = {}
    -- for index, value in ipairs(urTran.table) do
    --     urCN[value[1]] = true
    --     if myCNCSD[value[6]] then
    --         local find = false
    --         local change = false
    --         for _, idx in ipairs(myCNCSD[value[6]]) do
    --             if myTran.table[idx][1] == value[1] then
    --                 for i = 2, 5, 1 do
    --                     if value[i] ~= myTran.table[idx][i] then
    --                         myTran.table[idx][i] = value[i]
    --                         change = true
    --                     end
    --                 end
    --                 find = true
    --             end
    --         end
    --         if not find then
    --             misscn[#misscn + 1] = value
    --         else
    --             if change then
    --                 OKcn[#OKcn + 1] = value
    --             end
    --         end
    --     else
    --         idontknow[#idontknow + 1] = value
    --     end
    -- end
    -- myTran:write_to("D:\\Closers.cocos\\resource\\ui\\branches\\dzogame_sea\\zhcn\\trans.csv")
    -- urTran.write_to({ table = idontknow },
    --     "D:\\Closers.cocos\\resource\\ui\\branches\\dzogame_sea\\zhcn\\ur-trans-wrong.csv")
    -- urTran.write_to({ table = misscn }, "D:\\Closers.cocos\\resource\\ui\\branches\\dzogame_sea\\zhcn\\ur-trans-miss.csv")
    -- urTran.write_to({ table = OKcn }, "D:\\Closers.cocos\\resource\\ui\\branches\\dzogame_sea\\zhcn\\ur-trans-ok.csv")
    -- for key, value in pairs(myCN) do
    --     if urCN[key] then
    --     else
    --         print(key)
    --     end
    -- end
    -- for index, value in pairs(myCNCSD) do
    --     print(index, value)
    -- end
    -- while not stream.is_end do
    --     print(stream:check_next("我"), stream:next(), stream.line_number, stream.char_index)
    -- end
end, function(msg)
    print(msg)
end)
