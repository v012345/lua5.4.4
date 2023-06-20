require "lobject"

FIRST_RESERVED = 256
RESERVED = {
    -- terminal symbols denoted by reserved words
    ["TK_AND"] = 256,
    ["TK_BREAK"] = 257,
    ["TK_DO"] = 258,
    ["TK_ELSE"] = 259,
    ["TK_ELSEIF"] = 260,
    ["TK_END"] = 261,
    ["TK_FALSE"] = 262,
    ["TK_FOR"] = 263,
    ["TK_FUNCTION"] = 264,
    ["TK_GOTO"] = 265,
    ["TK_IF"] = 266,
    ["TK_IN"] = 267,
    ["TK_LOCAL"] = 268,
    ["TK_NIL"] = 269,
    ["TK_NOT"] = 270,
    ["TK_OR"] = 271,
    ["TK_REPEAT"] = 272,
    ["TK_RETURN"] = 273,
    ["TK_THEN"] = 274,
    ["TK_TRUE"] = 275,
    ["TK_UNTIL"] = 276,
    ["TK_WHILE"] = 277,
    ["TK_IDIV"] = 278,
    ["TK_CONCAT"] = 279,
    ["TK_DOTS"] = 280,
    ["TK_EQ"] = 281,
    ["TK_GE"] = 282,
    ["TK_LE"] = 283,
    ["TK_NE"] = 284,
    ["TK_SHL"] = 285,
    ["TK_SHR"] = 286,
    ["TK_DBCOLON"] = 287,
    ["TK_EOS"] = 288,
    ["TK_FLT"] = 289,
    ["TK_INT"] = 290,
    ["TK_NAME"] = 291,
    ["TK_STRING"] = 292,
}

---@diagnostic disable-next-line
luaX_tokens = {
    ["and"] = true,
    ["break"] = true,
    ["do"] = true,
    ["else"] = true,
    ["elseif"] = true,
    ["end"] = true,
    ["false"] = true,
    ["for"] = true,
    ["function"] = true,
    ["goto"] = true,
    ["if"] = true,
    ["in"] = true,
    ["local"] = true,
    ["nil"] = true,
    ["not"] = true,
    ["or"] = true,
    ["repeat"] = true,
    ["return"] = true,
    ["then"] = true,
    ["true"] = true,
    ["until"] = true,
    ["while"] = true,
    -- 其他终止符
    ["//"] = true,
    [".."] = true,
    ["..."] = true,
    ["=="] = true,
    [">="] = true,
    ["<="] = true,
    ["~="] = true,
    ["<<"] = true,
    [">>"] = true,
    ["::"] = true,
    ["<eof>"] = true,
    ["<number>"] = true,
    ["<integer>"] = true,
    ["<name>"] = true,
    ["<string>"] = true,
};


NUM_RESERVED = RESERVED.TK_WHILE - FIRST_RESERVED + 1

---@class SemInfo
SemInfo = {
    r = 0,
    i = 0,
    ts = "",
}

---@class Token
Token = {
    token = 0,
    seminfo = SemInfo
}


---@class LexState
LexState = {
    current = 0,            -- current character (charint)
    linenumber = 0,         -- input line counter
    lastline = 0,           -- line of last token 'consumed'
    ---@type Token
    t = new(Token),         -- current token
    ---@type Token
    lookahead = new(Token), -- look ahead token
    fs = nil,               -- current function (parser)
    L = nil,
    ---@type Zio
    z = nil, --input stream
    ---@type Mbuffer
    buff = {
        buffer = {},
        n = 0
    },              -- buffer for tokens
    ---@type Table
    h = new(Table), --to avoid collection/reuse strings
    dyd = nil,      -- dynamic structures used by the parser
    source = nil,   -- current source name
    envn = nil,     -- environment variable name
}

---@diagnostic disable-next-line
function luaX_init(L)

end

local function next(ls)
    ls.current = zgetc(ls.z)
end

---comment
---@param ls LexState
---@param c integer
local function save(ls, c)
    local b = ls.buff
    b.buffer[#b.buffer + 1] = c
    b.n = #b.buffer
end

---comment
---@param ls LexState
local function save_and_next(ls)
    save(ls, ls.current)
    next(ls)
end

local function currIsNewline(ls)
    if ls.current == string.byte('\n') or ls.current == string.byte('\r') then
        return true
    else
        return false
    end
end

---comment
---@param ls LexState
local function inclinenumber(ls)
    local old = ls.current;
    next(ls)     -- skip '\n' or '\r'
    if currIsNewline(ls) and ls.current ~= old then
        next(ls) -- skip '\n\r' or '\r\n'
    end
    ls.linenumber = ls.linenumber + 1
end

---comment
---@param ls LexState
---@return integer
local function skip_sep(ls)
    local count = 0
    local s = ls.current
    save_and_next(ls)
    while ls.current == string.byte("=") do
        save_and_next(ls)
        count = count + 1
    end
    if ls.current == s then
        return count + 2
    else
        if count == 0 then
            return 1
        else
            return 0
        end
    end
end

---comment
---@param ls LexState
---@param seminfo SemInfo | nil
---@param sep integer
local function read_long_string(ls, seminfo, sep)

end

local function check_next1(ls, c)
    if ls.current == c then
        next(ls)
        return 1
    else
        return 0
    end
end

---comment
---@param ls LexState
---@param seminfo SemInfo
---@return integer
local function llex(ls, seminfo)
    while true do
        ::start::
        if
            ls.current == string.byte("\n") or
            ls.current == string.byte("\r")
        then
            inclinenumber(ls)
            goto start
        elseif
            ls.current == string.byte(" ") or
            ls.current == string.byte("\f") or
            ls.current == string.byte("\t") or
            ls.current == string.byte("\v")
        then
            next(ls)
            goto start
        elseif ls.current == string.byte("-") then
            next(ls)
            if ls.current ~= string.byte("-") then
                return string.byte("-")
            end
            next(ls)
            if ls.current == string.byte("[") then
                local sep = skip_sep(ls)
                luaZ_resetbuffer(ls.buff)
                if sep >= 2 then
                    read_long_string(ls, nil, sep);
                    luaZ_resetbuffer(ls.buff)
                    goto start
                end
            end
        elseif ls.current == EOZ then
            return RESERVED.TK_EOS;
        else
            print(string.char(ls.current))
            next(ls)
        end
    end
    return 1
end



---comment
---@param ls LexState
---@diagnostic disable-next-line
function luaX_next(ls)
    ls.lastline = ls.linenumber
    if ls.lookahead.token ~= RESERVED.TK_EOS then --  is there a look-ahead token?
        ls.t = new(ls.lookahead);                 -- use this one
        ls.lookahead.token = RESERVED.TK_EOS;     -- and discharge it --
    else
        ls.t.token = llex(ls, ls.t.seminfo)
    end
    print(string.char(ls.t.token))
end

---comment
---@param ls LexState
---@param z Zio
---@diagnostic disable-next-line
function luaX_setinput(L, ls, z, source, firstchar)
    ls.t.token = 0;
    ls.L = L;
    ls.current = firstchar;
    ls.lookahead.token = RESERVED.TK_EOS; -- no look-ahead token
    ls.z = z;
    ls.fs = nil;
    ls.linenumber = 1;
    ls.lastline = 1;
    ls.source = source;
    ls.envn = "_ENV" -- get env name
    -- luaZ_resizebuffer(ls.L, ls.buff, LUA_MINBUFFER); -- initialize buffer
end
