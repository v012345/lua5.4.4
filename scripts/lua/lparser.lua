print(2)
require "lobject"
print(2)
require "llex"
print(2)


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

local function mainfunc(ls, fs)

end

function luaY_parser(L, z, buff, dyd, name, firstchar)
    ---@type LexState
    local lexstate = new(LexState)
    ---@type FuncState
    local funcstate = new(FuncState)
    ---@type Table
    lexstate.h = new(Table)
    ---@type Proto
    funcstate.f = new(Proto)
    luaX_setinput(L, lexstate, z, funcstate.f.source, firstchar);
    mainfunc(lexstate, funcstate);
end
