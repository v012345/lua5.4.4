local Parser = {
    ---@type LexState
    LexState = nil,
    position = 1,
    tokens_len = 1,
    token = {
        type = -1,
        value = "-1",
    },
    tokens = {},
    chunk = {},
    ast = {}
}
function Parser:init(lex)
    self.LexState = lex
    local t = lex:get_next_token()
    local e = self.LexState.type.end_of_file
    while t.type ~= e do
        self.tokens[#self.tokens + 1] = t
        t = lex:get_next_token()
    end
    self.tokens[#self.tokens + 1] = t
    self.position = 1
    self.token = self.tokens[self.position]
    self.tokens_len = #self.tokens
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
    if self.token.type == self.LexState.type.reserved then
        local v = self.token.value
        if v == "else" or v == "elseif" or v == "end" then
            return true
        elseif v == "until" then
            return withuntil
        end
    end
    if self.token.type == self.LexState.type.end_of_file then
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
    print(self.tokens_len)
    for index, value in ipairs(self.tokens) do
        print(value.type, value.value)
    end
    -- self.chunk.__name = "chunk"
    -- local block = {}
    -- block.__name = "block"
    -- self.LexState:get_next_token()
    -- self:statlist(block)
    -- self.chunk.block = block
end

function Parser:chunk()
    -- chunk ::= block
    local chunk = {}
    chunk.__name = "chunk"
    chunk[#chunk + 1] = self:block()
end

function Parser:block()
    -- block ::= {stat} [retstat]
    local block = {}
    block.__name = "block"
    while not self:block_follow(true) do
        if self.token.value == "return" and self.token.type == self.LexState.type.reserved then
            block[#block + 1] = self:retstat()
            return block
        end
        block[#block + 1] = self:stat()
    end
    return block
end

function Parser:retstat()

end

function Parser:next_token()
    self.position = self.position + 1
    self.token = self.tokens[self.position]
    return self.token
end

function Parser:stat(block)
    local token = self.token
    if token.type == self.LexState.type.other and token.value == ";" then
        self:next_token()
        return {
            __name = "stat",
            __value = ";"
        }
    elseif token.type == self.LexState.type.other and token.value == "::" then
        return self:label()
    elseif token.type == self.LexState.type.reserved and token.value == "break" then
        return self:break_()
    elseif token.type == self.LexState.type.reserved and token.value == "goto" then
        return self:goto_()
    elseif token.type == self.LexState.type.reserved and token.value == "do" then
        self:next_token() -- skip do
        local r = self:block()
        if not (self.token.type == self.LexState.type.reserved and self.token.value == "end") then
            error("do miss end")
        end
        self:next_token() -- skip end
        return r
    elseif token.type == self.LexState.type.reserved and token.value == "for" then
        return self:for_()
    elseif token.type == self.LexState.type.reserved and token.value == "repeat" then
        return self:repeat_()
    elseif token.type == self.LexState.type.reserved and token.value == "function" then
        return self:function_()
    elseif token.type == self.LexState.type.reserved and token.value == "if" then
        return self:if_()
    elseif token.type == self.LexState.type.reserved and token.value == "while" then
        return self:while_()
    elseif token.type == self.LexState.type.reserved and token.value == "local" then
        if self.LexState:test_next_token(self.LexState.type.reserved, "function") then
        else
            token = self.LexState:get_next_token()
            self:localstat(block)
        end
    else
        self:exp()
    end
end

function Parser:exp()

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
