local Parser = {
    lex = nil,
    tokens = {},
    token = nil,
    chunk = {},
    ast = {}
}
function Parser:init(lex)
    self.lex = lex
    local c = lex:next()
    while c.token ~= lex.END_OF_FILE do
        self.tokens[#self.tokens + 1] = c
        c = lex:next()
    end
end

function Parser:buildAST()
    for index, value in ipairs(self.tokens) do
        self.token = value
    end
end

function Parser:test()
    print(#self.tokens)
end

return Parser
