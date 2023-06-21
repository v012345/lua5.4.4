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
---@param e expdesc
---@param k expkind
---@param i integer
local function init_exp(e, k, i)
    e.f, e.t = NO_JUMP, NO_JUMP
    e.k = k;
    e.u.info = i;
end

---comment
---@param e expdesc
---@param s string
local function codestring(e, s)
    e.f, e.t = NO_JUMP, NO_JUMP
    e.k = expkind.VKSTR;
    e.u.strval = s;
end

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
---@param what integer
---@param who integer
---@param where integer
local function check_match(ls, what, who, where)
    if not testnext(ls, what) then
        error("check_match(ls, what, who, where)")
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

local function str_checkname(ls)
    check(ls, RESERVED.TK_NAME)
    local ts = ls.t.seminfo.ts
    luaX_next(ls)
    return ts
end

local function yindex(ls, v)
    luaX_next(ls)
    expr(ls, v)
    checknext(ls, string.byte(']'))
end

local function codename(ls, e)
    codestring(e, str_checkname(ls))
end

local function recfield(ls, cc)
    ---@type expdesc
    local tab = new(expdesc)
    ---@type expdesc
    local key = new(expdesc)
    ---@type expdesc
    local val = new(expdesc)
    if ls.t.token == RESERVED.TK_NAME then
        codename(ls, key)
    else
        yindex(ls, key)
    end
    checknext(ls, string.byte('='))
    expr(ls, val)
end

local function listfield(ls, cc)
    expr(ls, cc.v)
end

---comment
---@param ls LexState
---@param cc table
local function field(ls, cc)
    if ls.t.token == RESERVED.TK_NAME then
        if luaX_lookahead(ls) ~= string.byte("=") then
            listfield(ls, cc)
        else
            recfield(ls, cc)
        end
    elseif ls.t.token == string.byte("[") then
        recfield(ls, cc)
    else
        listfield(ls, cc)
    end
end

---comment
---@param ls LexState
---@param t expdesc
local function constructor(ls, t)
    local cc
    local line = ls.linenumber;
    checknext(ls, string.byte('{'))
    repeat
        if ls.t.token == string.byte("}") then
            break
        end
        field(ls, cc)
    until not (testnext(ls, string.byte(",") or testnext(ls, string.byte(";"))))
    check_match(ls, string.byte('}'), string.byte('{'), line)
end
local function new_localvar(ls, name)

end
local function parlist(ls)
    local isvararg = false
    if ls.t.token ~= string.byte(")") then
        repeat
            if ls.t.token == RESERVED.TK_NAME then
                new_localvar(ls, str_checkname(ls))
            elseif ls.t.token == RESERVED.TK_DOTS then
                luaX_next(ls)
                isvararg = true
            else
                error(debug.traceback("<name> or '...' expected"))
            end
        until isvararg or not testnext(ls, string.byte(","))
    end
end

local function body(ls, e, ismethod, line)
    checknext(ls, string.byte('('))
    parlist(ls)
    checknext(ls, string.byte(')'))
    statlist(ls)
    check_match(ls, RESERVED.TK_END, RESERVED.TK_FUNCTION, line)
end

local function singlevar(ls, var)
    str_checkname(ls)
end

local function primaryexp(ls, v)
    if ls.t.token == string.byte("(") then
        local line = ls.linenumber
        luaX_next(ls)
        expr(ls, v)
        check_match(ls, string.byte(')'), string.byte('('), line)
        return
    elseif ls.t.token == RESERVED.TK_NAME then
        singlevar(ls, v)
    else
        error(debug.traceback("unexpected symbol"))
    end
end

local function fieldsel(ls, v)
    local key = new(expdesc)
    luaX_next(ls)
    codename(ls, key)
end

local function explist(ls, v)
    local n = 1
    expr(ls, v)

    while testnext(ls, string.byte(',')) do
        expr(ls, v);
        n = n + 1
    end
    return n
end

local function funcargs(ls, f, line)
    local args = new(expdesc)
    if ls.t.token == string.byte("(") then
        luaX_next(ls)
        if ls.t.token == string.byte(")") then
        else
            explist(ls, args)
        end
        check_match(ls, string.byte(')'), string.byte('('), line)
    elseif ls.t.token == string.byte("{") then
        constructor(ls, args)
    elseif ls.t.token == RESERVED.TK_STRING then
        codestring(args, ls.t.seminfo.ts)
        luaX_next(ls)
    else
        error(debug.traceback("function arguments expected"))
    end
end

local function suffixedexp(ls, v)
    local line = ls.linenumber
    primaryexp(ls, v)
    while true do
        if ls.t.token == string.byte(".") then
            fieldsel(ls, v)
        elseif ls.t.token == string.byte("[") then
            local key = new(expdesc)
            yindex(ls, key)
        elseif ls.t.token == string.byte(":") then
            local key = new(expdesc)
            luaX_next(ls)
            codename(ls, key)
            funcargs(ls, v, line)
        elseif
            ls.t.token == string.byte("(") or
            ls.t.token == RESERVED.TK_STRING or
            ls.t.token == string.byte("{")
        then
            funcargs(ls, v, line)
        else
            return
        end
    end
end

---comment
---@param ls LexState
---@param v expdesc
local function simpleexp(ls, v)
    if ls.t.token == RESERVED.TK_FLT then
        init_exp(v, expkind.VKFLT, 0)
        v.u.nval = ls.t.seminfo.r
    elseif ls.t.token == RESERVED.TK_INT then
        init_exp(v, expkind.VKINT, 0)
        v.u.ival = ls.t.seminfo.i
    elseif ls.t.token == RESERVED.TK_STRING then
        codestring(v, ls.t.seminfo.ts)
    elseif ls.t.token == RESERVED.TK_NIL then
        init_exp(v, expkind.VNIL, 0)
    elseif ls.t.token == RESERVED.TK_TRUE then
        init_exp(v, expkind.VTRUE, 0)
    elseif ls.t.token == RESERVED.TK_FALSE then
        init_exp(v, expkind.VFALSE, 0)
    elseif ls.t.token == RESERVED.TK_DOTS then
        init_exp(v, expkind.VVARARG, 0)
    elseif ls.t.token == string.byte("{") then
        constructor(ls, v)
        return
    elseif ls.t.token == RESERVED.TK_FUNCTION then
        luaX_next(ls)
        body(ls, v, 0, ls.linenumber)
        return
    else
        suffixedexp(ls, v)
        return
    end
    luaX_next(ls)
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

---comment
---@param op integer
---@return BinOpr
local function getbinopr(op)
    local mt = {
        __index = function()
            return BinOpr.OPR_NOBINOPR
        end
    }
    local t = {
        [string.byte("+")] = BinOpr.OPR_ADD,
        [string.byte("-")] = BinOpr.OPR_SUB,
        [string.byte("*")] = BinOpr.OPR_MUL,
        [string.byte("%")] = BinOpr.OPR_MOD,
        [string.byte("^")] = BinOpr.OPR_POW,
        [string.byte("/")] = BinOpr.OPR_DIV,
        [RESERVED.TK_IDIV] = BinOpr.OPR_IDIV,
        [string.byte("&")] = BinOpr.OPR_BAND,
        [string.byte("|")] = BinOpr.OPR_BOR,
        [string.byte("~")] = BinOpr.OPR_BXOR,
        [RESERVED.TK_SHL] = BinOpr.OPR_SHL,
        [RESERVED.TK_SHR] = BinOpr.OPR_SHR,
        [RESERVED.TK_CONCAT] = BinOpr.OPR_CONCAT,
        [RESERVED.TK_NE] = BinOpr.OPR_NE,
        [RESERVED.TK_EQ] = BinOpr.OPR_EQ,
        [string.byte("<")] = BinOpr.OPR_LT,
        [RESERVED.TK_LE] = BinOpr.OPR_LE,
        [string.byte(">")] = BinOpr.OPR_GT,
        [RESERVED.TK_GE] = BinOpr.OPR_GE,
        [RESERVED.TK_AND] = BinOpr.OPR_AND,
        [RESERVED.TK_OR] = BinOpr.OPR_OR,
    }
    setmetatable(t, mt)
    return t[op]
end

UNARY_PRIORITY = 12
---comment
---@param ls LexState
---@param v expdesc
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
    check_match(ls, RESERVED.TK_END, RESERVED.TK_IF, line)
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
