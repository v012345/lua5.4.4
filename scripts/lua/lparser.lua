require "lobject"
require "llex"
require "lcode"


---@class FuncState
FuncState = {
    ---@type Proto
    f = new(Proto),   -- current function header
    prev = nil,       -- enclosing function
    ls = nil,         -- lexical state
    bl = nil,         -- chain of current blocks
    pc = 0,           -- next position to code (equivalent to 'ncode')
    lasttarget = 0,   -- 'label' of last 'jump label'
    previousline = 0, -- last line that was saved in 'lineinfo'
    nk = 0,           -- number of elements in 'k'
    np = 0,           -- number of elements in 'p'
    nabslineinfo = 0, -- number of elements in 'abslineinfo'
    firstlocal = 0,   -- index of first local var (in Dyndata array)
    firstlabel = 0,   -- index of first label (in 'dyd->label->arr')
    ndebugvars = 0,   -- number of elements in 'f->locvars'
    nactvar = 0,      -- number of active local variables
    nups = 0,         -- number of upvalues
    freereg = 0,      -- first free register
    iwthabs = 0,      -- instructions issued since last absolute line info
    needclose = 0,    -- function needs to close upvalues when returning
}

---@enum expkind
---@diagnostic disable-next-line
expkind = {
    VVOID = 0,
    VNIL = 1,
    VTRUE = 2,
    VFALSE = 3,
    VK = 4,
    VKFLT = 5,
    VKINT = 6,
    VKSTR = 7,
    VNONRELOC = 8,
    VLOCAL = 9,
    VUPVAL = 10,
    VCONST = 11,
    VINDEXED = 12,
    VINDEXUP = 13,
    VINDEXI = 14,
    VINDEXSTR = 15,
    VJMP = 16,
    VRELOC = 17,
    VCALL = 18,
    VVARARG = 19
}

---@class expdesc
expdesc = {
    ---@type expkind
    k = expkind.VVOID,
    u = {
        ival = 0,
        nval = 0,
        strval = "",
        info = 0,
        ind = {
            idx = 0,
            t = 0
        },
        var = {
            ridx = 0,
            vidx = 0
        }
    },
    t = NO_JUMP,
    f = NO_JUMP,
}

local statement = function(ls) end
local expr = function(ls, v) end

---comment
---@param ls LexState
---@param withuntil boolean
local function block_follow(ls, withuntil)
    if
        ls.t.token == RESERVED.TK_ELSE or
        ls.t.token == RESERVED.TK_ELSEIF or
        ls.t.token == RESERVED.TK_END or
        ls.t.token == RESERVED.TK_EOS
    then
        return true
    elseif ls.t.token == RESERVED.TK_UNTIL then
        return withuntil
    else
        return false
    end
end

---comment
---@param ls LexState
---@param c integer
local function check(ls, c)
    if ls.t.token ~= c then
        error(debug.traceback("ls.t.token ~= c"))
    end
end

---comment
---@param ls LexState
---@param c integer
local function checknext(ls, c)
    check(ls, c)
    luaX_next(ls)
end

---comment
---@param ls LexState
---@param c integer
local function testnext(ls, c)
    if ls.t.token == c then
        luaX_next(ls)
        return true
    else
        return false
    end
end

---comment
---@param ls LexState
local function statlist(ls)
    while not block_follow(ls, true) do
        if ls.t.token == RESERVED.TK_RETURN then
            statement(ls)
            return
        end
        statement(ls)
    end
end

---comment
---@param ls LexState
---@param escapelist table
local function test_then_block(ls, escapelist)
    local v = {}
    luaX_next(ls)
    expr(ls, v)
    checknext(ls, RESERVED.TK_THEN)
    if ls.t.token == RESERVED.TK_BREAK then
        error(debug.traceback("unimplented if x then break"))
    else
    end
    statlist(ls)
end

local function simpleexp(ls, v)
    if ls.t.token == RESERVED.TK_FLT then

    end
end

---comment
---@param op integer
---@return UnOpr
local function getunopr(op)
    if op == RESERVED.TK_NOT then
        return UnOpr.OPR_NOT
    elseif op == string.byte("-") then
        return UnOpr.OPR_MINUS
    elseif op == string.byte("~") then
        return UnOpr.OPR_BNOT
    elseif op == string.byte("#") then
        return UnOpr.OPR_LEN
    else
        return UnOpr.OPR_NOUNOPR
    end
end
UNARY_PRIORITY = 12
---comment
---@param ls LexState
---@param v table
---@param limit integer
local function subexpr(ls, v, limit)
    local uop = getunopr(ls.t.token)
    if uop ~= UnOpr.OPR_NOUNOPR then
        local line = ls.linenumber
        luaX_next(ls)
        subexpr(ls, v, UNARY_PRIORITY)
    else
        simpleexp(ls, v)
    end
end

---comment
---@param ls LexState
---@param v table
function expr(ls, v)
    subexpr(ls, v, 0)
end

---comment
---@param ls LexState
local function block(ls)
    local fs = ls.fs
    statlist(ls)
end
---comment
---@param ls LexState
---@param line integer
local function ifstat(ls, line)
    local fs = ls.fs
    local escapelist = {
        value = NO_JUMP
    }
    test_then_block(ls, escapelist)
    while ls.t.token == RESERVED.TK_ELSEIF do
        test_then_block(ls, escapelist)
    end
    if testnext(ls, RESERVED.TK_ELSE) then
        block(ls)
    end
end
---comment
---@param ls LexState
function statement(ls)
    local line = ls.linenumber
    if ls.t.token == string.byte(";") then
        luaX_next(ls)
    elseif ls.t.token == RESERVED.TK_IF then
        ifstat(ls, line)
    elseif ls.t.token == RESERVED.TK_WHILE then
        luaX_next(ls)
    elseif ls.t.token == RESERVED.TK_DO then
        luaX_next(ls)
    elseif ls.t.token == RESERVED.TK_FOR then
        luaX_next(ls)
    elseif ls.t.token == RESERVED.TK_REPEAT then
        luaX_next(ls)
    elseif ls.t.token == RESERVED.TK_FUNCTION then
        luaX_next(ls)
    elseif ls.t.token == RESERVED.TK_LOCAL then
        luaX_next(ls)
    elseif ls.t.token == RESERVED.TK_DBCOLON then
        luaX_next(ls)
    elseif ls.t.token == RESERVED.TK_RETURN then
        luaX_next(ls)
    elseif ls.t.token == RESERVED.TK_BREAK then
        luaX_next(ls)
    elseif ls.t.token == RESERVED.TK_GOTO then
        luaX_next(ls)
    else
        luaX_next(ls)
    end
end

local function mainfunc(ls, fs)
    luaX_next(ls);
    statlist(ls);
end

---comment
---@param L any
---@param z Zio
---@param buff Mbuffer
---@param dyd any
---@param name string
---@param firstchar integer
---@diagnostic disable-next-line
function luaY_parser(L, z, buff, dyd, name, firstchar)
    ---@type LexState
    local lexstate = new(LexState)
    ---@type FuncState
    local funcstate = new(FuncState)
    ---@type Table
    lexstate.h = new(Table)
    ---@type Proto
    funcstate.f = new(Proto)
    funcstate.f.source = name

    lexstate.buff = buff
    luaX_setinput(L, lexstate, z, funcstate.f.source, firstchar);
    mainfunc(lexstate, funcstate);
end
