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
            token = self.LexState:get_next_token()
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

function Parser:ifstat()
    self:test_then_block()
end

function Parser:test_then_block()
    local token = self.LexState:get_next_token() -- 跳过 if or elseif
    self:expr()
end

function Parser:expr()
    self:subexpr(0)
end

function Parser:subexpr(limit)
    self:subexpr()
end

function Parser:getunopr()

end

function Parser:mainfunc()
    local block = {}
    self:statlist(block)
    self.chunk.__name = "chunk"
    self.chunk.block = block
end

function Parser:test()
    self:mainfunc()
end

return Parser
