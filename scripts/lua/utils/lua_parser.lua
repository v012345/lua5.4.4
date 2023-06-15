local Parser = {
    ---@type LexState
    LexState = nil,
    chunk = {},
    ast = {}
}
function Parser:init(lex)
    self.LexState = lex
end

function Parser:statlist(block)
    while not self:block_follow(true) do
        if self.LexState.token.value == "return" and self.LexState.token.type == self.LexState.type.reserved then
            self:statement(block)
            return
        end
        self:statement(block)
    end
end

function Parser:block_follow(withuntil)
    if self.LexState.token.type == self.LexState.type.reserved then
        local v = self.LexState.token.value
        if v == "else" or v == "elseif" or v == "end" then
            return true
        elseif v == "until" then
            return withuntil
        end
    end
    if self.LexState.token.type == self.LexState.type.end_of_file then
        return true
    end
    return false
end

function Parser:statement(block)
    local token = self.LexState.token
    if token then
        if token.type == self.LexState.type.other and token.value == ";" then
            token = self.LexState:get_next_token()
            goto end_switch
        elseif token.type == self.LexState.type.reserved and token.value == "if" then
            self:ifstat()
            goto end_switch
        elseif token.type == self.LexState.type.reserved and token.value == "local" then
            if self.LexState:test_next_token(self.LexState.type.reserved, "function") then
            else
                token = self.LexState:get_next_token()
                self:localstat(block)
            end
            goto end_switch
        end
    end
    ::end_switch::
end

function Parser:buildAST()
    if self.token.token == ";" then
    elseif self.token.token == 0 and self.token.value == "if" then

    end
end

function Parser:localstat(block)
    local stat = {}
    stat.__name = "local"
    block[#block + 1] = stat
    self:attnamelist(stat)
    if self.LexState:test_next_token(self.LexState.type.other, "=") then
        self.LexState:get_next_token()
        self.LexState:get_next_token()
        self:explist(stat)
    end
end

function Parser:attnamelist(stat)
    local attnamelist = {}
    stat.attnamelist = attnamelist
    attnamelist.__name = "attnamelist"
    print(">>>>>>>>>>>>")
    repeat
        local var = {}
        var.__name = "name"
        print("++++++")
        local token = self.LexState.token
        print(self.LexState.token.value)
        if token.type ~= self.LexState.type.name then
            self.LexState:error("not a local var")
        end
        var.__value = token.value
        if self.LexState:test_next_token(self.LexState.type.other, "<") then
            self.LexState:get_next_token()
            self.LexState:get_next_token()
            self:attrib(var)
            self.LexState:get_next_token()
        end
        attnamelist[#attnamelist + 1] = var
        local bye = self.LexState:test_next_token(self.LexState.type.other, ",")
        print(bye)
        if bye then
            self.LexState:get_next_token()
            self.LexState:get_next_token()
        end
    until not bye
    print("<<<<<<<<<<<<<<")
    -- self:attnamelist(block)
end

function Parser:attrib(var)
    local token = self.LexState.token
    print(token.value)
    local attr = {}
    attr.__name = "name"
    attr.__value = token.value
    var.attrib = attr
end

function Parser:explist(stat)
    local explist = {}
    explist.__name = "explist"
    repeat
        explist[#explist + 1] = self:expr()
        local bye = self.LexState:test_next_token(self.LexState.type.other, ",")
        print(bye)
        if bye then
            self.LexState:get_next_token()
            self.LexState:get_next_token()
        end
    until not bye
    stat.explist = explist
end

function Parser:ifstat()
    self:test_then_block()
end

function Parser:test_then_block()
    local token = self.LexState:get_next_token() -- 跳过 if or elseif
    self:expr()
end

function Parser:expr()
    local expr = {}
    expr.__name = "exp"
    self:subexpr(expr, 0)
    return expr
end

function Parser:subexpr(expr, limit)
    local token = self.LexState.token
    local uop = self:getunopr(token);
    if uop then
    else
        self:simpleexp();
    end
end

function Parser:getunopr(token)
    if token.type == self.LexState.type.reserved and token.value == "not" then
        return true
    end
    if token.type == self.LexState.type.other then
        if token.value == "-" or token.value == "~" or token.value == "#"
        then
            return true
        end
    end
    return false
end

function Parser:mainfunc()
    self.chunk.__name = "chunk"
    local block = {}
    block.__name = "block"
    self.LexState:get_next_token()
    self:statlist(block)
    self.chunk.block = block
end

function Parser:test()
    self:mainfunc()
    self:write_to_lua_file("C:\\Users\\Meteor\\Desktop\\configs\\ast.lua", "ast", self.chunk)
end

function Parser:write_to_lua_file(toLua, table_name, data)
    local j = 0
    local function dump(t, o, q)
        if type(t) == 'table' then
            j = j + 1
            o:write('{\n')
            for k, v in pairs(t) do
                for i = 1, j, 1 do
                    o:write("    ")
                end
                if tonumber(k) then
                    o:write(string.format("[%s] = ", k))
                else
                    o:write(string.format("%s = ", k))
                end
                dump(v, o, true)
            end
            j = j - 1
            for i = 1, j, 1 do
                o:write("    ")
            end

            if q then
                o:write('},\n')
            else
                o:write('}\n')
            end
        elseif type(t) == "string" then
            local n = tonumber(t)
            if n then
                o:write(n)
            else
                o:write(string.format('"%s"', t))
            end
            o:write(",")
            o:write("\n")
        end
    end
    local o = io.open(toLua, "w") or error("can't write")
    o:write(string.format("local %s = ", table_name))
    dump(data, o, false)
    o:write("\n")
    o:write("return " .. table_name)
    o:close()
end

return Parser
