require "lobject"
require "llex"


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

---comment
---@param ls LexState
---@param withuntil boolean
local function block_follow(ls, withuntil)
    if
        ls.t.token == RESERVED["TK_ELSE"] or
        ls.t.token == RESERVED["TK_ELSEIF"] or
        ls.t.token == RESERVED["TK_END"] or
        ls.t.token == RESERVED["TK_EOS"]
    then
        return true
    elseif ls.t.token == RESERVED["TK_UNTIL"] then
        return withuntil
    else
        return false
    end
end

---comment
---@param ls LexState
local function statement(ls)
    print("local function statement(ls)")
    local line = ls.linenumber
    if ls.t.token == string.byte(";") then
        luaX_next(ls)
    elseif ls.t.token == RESERVED["TK_IF"] then
        luaX_next(ls)
    elseif ls.t.token == RESERVED["TK_WHILE"] then
        luaX_next(ls)
    elseif ls.t.token == RESERVED["TK_DO"] then
        luaX_next(ls)
    elseif ls.t.token == RESERVED["TK_FOR"] then
        luaX_next(ls)
    elseif ls.t.token == RESERVED["TK_REPEAT"] then
        luaX_next(ls)
    elseif ls.t.token == RESERVED["TK_FUNCTION"] then
        luaX_next(ls)
    elseif ls.t.token == RESERVED["TK_LOCAL"] then
        luaX_next(ls)
    elseif ls.t.token == RESERVED["TK_DBCOLON"] then
        luaX_next(ls)
    elseif ls.t.token == RESERVED["TK_RETURN"] then
        luaX_next(ls)
    elseif ls.t.token == RESERVED["TK_BREAK"] then
        luaX_next(ls)
    elseif ls.t.token == RESERVED["TK_GOTO"] then
        luaX_next(ls)
    else
        luaX_next(ls)
    end
end

---comment
---@param ls LexState
local function statlist(ls)
    while block_follow(ls, true) do
        if ls.t.token == RESERVED["TK_RETURN"] then
            statement(ls)
            return
        end
        statement(ls)
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
