Bytedump = {
    A_pos = 7,
    A_mask = 0x7F80,
    B_pos = 16,
    B_mask = 0xFF0000,
    sB_pos = 16,
    sB_mask = 0xFF0000,
    sB_offset = 0x7F,
    Bx_pos = 15,
    Bx_mask = 0xFFFF8000,
    sBx_pos = 15,
    sBx_offset = 0xFFFF,
    C_pos = 24,
    C_mask = 0xFF000000,
    sC_pos = 24,
    sC_mask = 0xFF000000,
    sC_offset = 0x7F,
    k_pos = 15,
    k_mask = 0x8000,
    sJ_pos = 7,
    sJ_mask = 0xFFFFFFF8,
    sJ_offset = 0xFFFFFF,
    codes = {},
}

local OpMode = {
    iABC = 0,
    iABx = 1,
    iAsBx = 2,
    iAx = 3,
    isJ = 4
}

local function opmode(mm, ot, it, t, a, m)
    return ((mm) << 7) | ((ot) << 6) | ((it) << 5) | ((t) << 4) | ((a) << 3) | (m)
end

local opmodes = {
    -- masks for instruction properties. The format is:
    -- bits 0-2: op mode
    -- bit 3: instruction set register A
    -- bit 4: operator is a test (next instruction must be a jump)
    -- bit 5: instruction uses 'L->top' set by previous instruction (when B == 0)
    -- bit 6: instruction sets 'L->top' for next instruction (when C == 0)
    -- bit 7: instruction is an MM instruction (call a metamethod)
    opmode(0, 0, 0, 0, 1, OpMode.iABC),  -- OP_MOVE
    opmode(0, 0, 0, 0, 1, OpMode.iAsBx), -- OP_LOADI
    opmode(0, 0, 0, 0, 1, OpMode.iAsBx), -- OP_LOADF
    opmode(0, 0, 0, 0, 1, OpMode.iABx),  -- OP_LOADK
    opmode(0, 0, 0, 0, 1, OpMode.iABx),  -- OP_LOADKX
    opmode(0, 0, 0, 0, 1, OpMode.iABC),  -- OP_LOADFALSE
    opmode(0, 0, 0, 0, 1, OpMode.iABC),  -- OP_LFALSESKIP
    opmode(0, 0, 0, 0, 1, OpMode.iABC),  -- OP_LOADTRUE
    opmode(0, 0, 0, 0, 1, OpMode.iABC),  -- OP_LOADNIL
    opmode(0, 0, 0, 0, 1, OpMode.iABC),  -- OP_GETUPVAL
    opmode(0, 0, 0, 0, 0, OpMode.iABC),  -- OP_SETUPVAL
    opmode(0, 0, 0, 0, 1, OpMode.iABC),  -- OP_GETTABUP
    opmode(0, 0, 0, 0, 1, OpMode.iABC),  -- OP_GETTABLE
    opmode(0, 0, 0, 0, 1, OpMode.iABC),  -- OP_GETI
    opmode(0, 0, 0, 0, 1, OpMode.iABC),  -- OP_GETFIELD
    opmode(0, 0, 0, 0, 0, OpMode.iABC),  -- OP_SETTABUP
    opmode(0, 0, 0, 0, 0, OpMode.iABC),  -- OP_SETTABLE
    opmode(0, 0, 0, 0, 0, OpMode.iABC),  -- OP_SETI
    opmode(0, 0, 0, 0, 0, OpMode.iABC),  -- OP_SETFIELD
    opmode(0, 0, 0, 0, 1, OpMode.iABC),  -- OP_NEWTABLE
    opmode(0, 0, 0, 0, 1, OpMode.iABC),  -- OP_SELF
    opmode(0, 0, 0, 0, 1, OpMode.iABC),  -- OP_ADDI
    opmode(0, 0, 0, 0, 1, OpMode.iABC),  -- OP_ADDK
    opmode(0, 0, 0, 0, 1, OpMode.iABC),  -- OP_SUBK
    opmode(0, 0, 0, 0, 1, OpMode.iABC),  -- OP_MULK
    opmode(0, 0, 0, 0, 1, OpMode.iABC),  -- OP_MODK
    opmode(0, 0, 0, 0, 1, OpMode.iABC),  -- OP_POWK
    opmode(0, 0, 0, 0, 1, OpMode.iABC),  -- OP_DIVK
    opmode(0, 0, 0, 0, 1, OpMode.iABC),  -- OP_IDIVK
    opmode(0, 0, 0, 0, 1, OpMode.iABC),  -- OP_BANDK
    opmode(0, 0, 0, 0, 1, OpMode.iABC),  -- OP_BORK
    opmode(0, 0, 0, 0, 1, OpMode.iABC),  -- OP_BXORK
    opmode(0, 0, 0, 0, 1, OpMode.iABC),  -- OP_SHRI
    opmode(0, 0, 0, 0, 1, OpMode.iABC),  -- OP_SHLI
    opmode(0, 0, 0, 0, 1, OpMode.iABC),  -- OP_ADD
    opmode(0, 0, 0, 0, 1, OpMode.iABC),  -- OP_SUB
    opmode(0, 0, 0, 0, 1, OpMode.iABC),  -- OP_MUL
    opmode(0, 0, 0, 0, 1, OpMode.iABC),  -- OP_MOD
    opmode(0, 0, 0, 0, 1, OpMode.iABC),  -- OP_POW
    opmode(0, 0, 0, 0, 1, OpMode.iABC),  -- OP_DIV
    opmode(0, 0, 0, 0, 1, OpMode.iABC),  -- OP_IDIV
    opmode(0, 0, 0, 0, 1, OpMode.iABC),  -- OP_BAND
    opmode(0, 0, 0, 0, 1, OpMode.iABC),  -- OP_BOR
    opmode(0, 0, 0, 0, 1, OpMode.iABC),  -- OP_BXOR
    opmode(0, 0, 0, 0, 1, OpMode.iABC),  -- OP_SHL
    opmode(0, 0, 0, 0, 1, OpMode.iABC),  -- OP_SHR
    opmode(1, 0, 0, 0, 0, OpMode.iABC),  -- OP_MMBIN
    opmode(1, 0, 0, 0, 0, OpMode.iABC),  -- OP_MMBINI
    opmode(1, 0, 0, 0, 0, OpMode.iABC),  -- OP_MMBINK
    opmode(0, 0, 0, 0, 1, OpMode.iABC),  -- OP_UNM
    opmode(0, 0, 0, 0, 1, OpMode.iABC),  -- OP_BNOT
    opmode(0, 0, 0, 0, 1, OpMode.iABC),  -- OP_NOT
    opmode(0, 0, 0, 0, 1, OpMode.iABC),  -- OP_LEN
    opmode(0, 0, 0, 0, 1, OpMode.iABC),  -- OP_CONCAT
    opmode(0, 0, 0, 0, 0, OpMode.iABC),  -- OP_CLOSE
    opmode(0, 0, 0, 0, 0, OpMode.iABC),  -- OP_TBC
    opmode(0, 0, 0, 0, 0, OpMode.isJ),   -- OP_JMP
    opmode(0, 0, 0, 1, 0, OpMode.iABC),  -- OP_EQ
    opmode(0, 0, 0, 1, 0, OpMode.iABC),  -- OP_LT
    opmode(0, 0, 0, 1, 0, OpMode.iABC),  -- OP_LE
    opmode(0, 0, 0, 1, 0, OpMode.iABC),  -- OP_EQK
    opmode(0, 0, 0, 1, 0, OpMode.iABC),  -- OP_EQI
    opmode(0, 0, 0, 1, 0, OpMode.iABC),  -- OP_LTI
    opmode(0, 0, 0, 1, 0, OpMode.iABC),  -- OP_LEI
    opmode(0, 0, 0, 1, 0, OpMode.iABC),  -- OP_GTI
    opmode(0, 0, 0, 1, 0, OpMode.iABC),  -- OP_GEI
    opmode(0, 0, 0, 1, 0, OpMode.iABC),  -- OP_TEST
    opmode(0, 0, 0, 1, 1, OpMode.iABC),  -- OP_TESTSET
    opmode(0, 1, 1, 0, 1, OpMode.iABC),  -- OP_CALL
    opmode(0, 1, 1, 0, 1, OpMode.iABC),  -- OP_TAILCALL
    opmode(0, 0, 1, 0, 0, OpMode.iABC),  -- OP_RETURN
    opmode(0, 0, 0, 0, 0, OpMode.iABC),  -- OP_RETURN0
    opmode(0, 0, 0, 0, 0, OpMode.iABC),  -- OP_RETURN1
    opmode(0, 0, 0, 0, 1, OpMode.iABx),  -- OP_FORLOOP
    opmode(0, 0, 0, 0, 1, OpMode.iABx),  -- OP_FORPREP
    opmode(0, 0, 0, 0, 0, OpMode.iABx),  -- OP_TFORPREP
    opmode(0, 0, 0, 0, 0, OpMode.iABC),  -- OP_TFORCALL
    opmode(0, 0, 0, 0, 1, OpMode.iABx),  -- OP_TFORLOOP
    opmode(0, 0, 1, 0, 0, OpMode.iABC),  -- OP_SETLIST
    opmode(0, 0, 0, 0, 1, OpMode.iABx),  -- OP_CLOSURE
    opmode(0, 1, 0, 0, 1, OpMode.iABC),  -- OP_VARARG
    opmode(0, 0, 1, 0, 1, OpMode.iABC),  -- OP_VARARGPREP
    opmode(0, 0, 0, 0, 0, OpMode.iAx),   -- OP_EXTRAARG
};

-- "in top" (uses top from previous instruction)
-- function isIT(i)
--     return (testITMode(GET_OPCODE(i)) && GETARG_B(i) == 0)
-- end


local TM = {
    "__index",
    "__newindex",
    "__gc",
    "__mode",
    "__len",
    "__eq",
    "__add",
    "__sub",
    "__mul",
    "__mod",
    "__pow",
    "__div",
    "__idiv",
    "__band",
    "__bor",
    "__bxor",
    "__shl",
    "__shr",
    "__unm",
    "__bnot",
    "__lt",
    "__le",
    "__concat",
    "__call",
    "__close",
}


local OP_CODE = {
    "OP_MOVE",
    "OP_LOADI",
    "OP_LOADF",
    "OP_LOADK",
    "OP_LOADKX",
    "OP_LOADFALSE",
    "OP_LFALSESKIP",
    "OP_LOADTRUE",
    "OP_LOADNIL",
    "OP_GETUPVAL",
    "OP_SETUPVAL",
    "OP_GETTABUP",
    "OP_GETTABLE",
    "OP_GETI",
    "OP_GETFIELD",
    "OP_SETTABUP",
    "OP_SETTABLE",
    "OP_SETI",
    "OP_SETFIELD",
    "OP_NEWTABLE",
    "OP_SELF",
    "OP_ADDI",
    "OP_ADDK",
    "OP_SUBK",
    "OP_MULK",
    "OP_MODK",
    "OP_POWK",
    "OP_DIVK",
    "OP_IDIVK",
    "OP_BANDK",
    "OP_BORK",
    "OP_BXORK",
    "OP_SHRI",
    "OP_SHLI",
    "OP_ADD",
    "OP_SUB",
    "OP_MUL",
    "OP_MOD",
    "OP_POW",
    "OP_DIV",
    "OP_IDIV",
    "OP_BAND",
    "OP_BOR",
    "OP_BXOR",
    "OP_SHL",
    "OP_SHR",
    "OP_MMBIN",
    "OP_MMBINI",
    "OP_MMBINK",
    "OP_UNM",
    "OP_BNOT",
    "OP_NOT",
    "OP_LEN",
    "OP_CONCAT",
    "OP_CLOSE",
    "OP_TBC",
    "OP_JMP",
    "OP_EQ",
    "OP_LT",
    "OP_LE",
    "OP_EQK",
    "OP_EQI",
    "OP_LTI",
    "OP_LEI",
    "OP_GTI",
    "OP_GEI",
    "OP_TEST",
    "OP_TESTSET",
    "OP_CALL",
    "OP_TAILCALL",
    "OP_RETURN",
    "OP_RETURN0",
    "OP_RETURN1",
    "OP_FORLOOP",
    "OP_FORPREP",
    "OP_TFORPREP",
    "OP_TFORCALL",
    "OP_TFORLOOP",
    "OP_SETLIST",
    "OP_CLOSURE",
    "OP_VARARG",
    "OP_VARARGPREP",
    "OP_EXTRAARG"
}

local function getMode(code)
    local pc = (code & 0x7F) + 1
    local modes = {
        "iABC", "iABx", "iAsBx", "iAx", "isJ"
    }
    local pcmode = opmodes[pc]
    -- print((pcmode & 7) + 1)
    local mode = modes[(pcmode & 7) + 1]
    mode = mode .. "\t"
    if (pcmode & 8) == 8 then
        mode = mode .. "A "
    else
        mode = mode .. "  "
    end
    if (pcmode & 16) == 16 then
        mode = mode .. "T "
    else
        mode = mode .. "  "
    end
    if (pcmode & 32) == 32 and Bytedump:B(code) == 0 then
        mode = mode .. "IT "
    else
        mode = mode .. "   "
    end
    if (pcmode & 64) == 64 and Bytedump:C(code) == 0 or OP_CODE[pc] == "OP_TAILCALL" then
        -- (testOTMode(GET_OPCODE(i)) && GETARG_C(i) == 0) || GET_OPCODE(i) ==
        mode = mode .. "OT "
    else
        mode = mode .. "   "
    end
    if (pcmode & 128) == 128 then
        mode = mode .. "MM"
    else
        mode = mode .. "  "
    end
    -- print(mode)
    return mode
end


local OP_ACT = {
    OP_MOVE = function(index, code)
        local f = "R[%s] = R[%s]"
        local name = OP_CODE[(code & 0x7F) + 1]
        local B = Bytedump:B(code)
        local A = Bytedump:A(code)
        print(index, name, "", getMode(code), string.format(f, A, B))
    end,
    OP_LOADI = function(index, code)
        local f = "R[%s] = sBx:%s"
        local name = OP_CODE[(code & 0x7F) + 1]
        local sBx = Bytedump:sBx(code)
        local A = Bytedump:A(code)
        print(index, name, getMode(code), string.format(f, A, sBx))
    end,
    OP_LOADF = function(index, code)
        local f = "R[%s] = (double)sBx:%s"
        local name = OP_CODE[(code & 0x7F) + 1]
        local sBx = Bytedump:sBx(code)
        local A = Bytedump:A(code)
        print(index, name, getMode(code), string.format(f, A, sBx))
    end,
    OP_LOADK = function(index, code)
        local f = "R[%s] = K[%s]"
        local name = OP_CODE[(code & 0x7F) + 1]
        local A = Bytedump:A(code)
        local Bx = Bytedump:Bx(code)
        print(index, name, getMode(code), string.format(f, A, Bx))
    end,
    OP_LOADKX = nil, -- 常量个数大于 2^17 -1 之后, 才会用到这个指令
    OP_LOADFALSE = function(index, code)
        local f = "R[%s] = false"
        local name = OP_CODE[(code & 0x7F) + 1]
        local A = Bytedump:A(code)
        print(index, name, getMode(code), string.format(f, A))
    end,
    OP_LFALSESKIP = function(index, code)
        local f = "R[%s] = false goto %s"
        local name = OP_CODE[(code & 0x7F) + 1]
        local A = Bytedump:A(code)
        print(index, name, getMode(code), string.format(f, A, index + 2))
    end,
    OP_LOADTRUE = function(index, code)
        local f = "R[%s] = true"
        local name = OP_CODE[(code & 0x7F) + 1]
        local A = Bytedump:A(code)
        print(index, name, getMode(code), string.format(f, A))
    end,
    OP_LOADNIL = function(index, code)
        local f = "for i = 0 to %s then R[%s+i] = nil"
        local name = OP_CODE[(code & 0x7F) + 1]
        local A = Bytedump:A(code)
        local B = Bytedump:B(code)
        print(index, name, getMode(code), string.format(f, B, A))
    end,
    OP_GETUPVAL = function(index, code)
        -- R[A] := UpValue[B]
        local f = "R[%s] = UpValue[%s]"
        local name = OP_CODE[(code & 0x7F) + 1]
        local A = Bytedump:A(code)
        local B = Bytedump:B(code)
        print(index, name, getMode(code), string.format(f, A, B))
    end,
    OP_SETUPVAL = function(index, code)
        -- UpValue[B] := R[A]
        local f = "UpValue[%s] = R[%s]"
        local name = OP_CODE[(code & 0x7F) + 1]
        local A = Bytedump:A(code)
        local B = Bytedump:B(code)
        print(index, name, getMode(code), string.format(f, B, A))
    end,
    OP_GETTABUP = function(index, code)
        local f = "R[%s] = UpValue[%s][K[%s]]"
        local name = OP_CODE[(code & 0x7F) + 1]
        local A = Bytedump:A(code)
        local B = Bytedump:B(code)
        local C = Bytedump:C(code)
        print(index, name, getMode(code), string.format(f, A, B, C))
    end,
    OP_GETTABLE = function(index, code)
        -- R[A] := R[B][R[C]]
        local name = OP_CODE[(code & 0x7F) + 1]
        local f = "R[%s] = R[%s][R[%s]]"
        local A = Bytedump:A(code)
        local B = Bytedump:B(code)
        local C = Bytedump:C(code)
        print(index, name, getMode(code), string.format(f, A, B, C))
    end,
    OP_GETI = function(index, code)
        local name = OP_CODE[(code & 0x7F) + 1]
        local f = "R[%s] = R[%s][C:%s]"
        local A = Bytedump:A(code)
        local B = Bytedump:B(code)
        local C = Bytedump:C(code)
        print(index, name, "", getMode(code), string.format(f, A, B, C))
    end,
    OP_GETFIELD = function(index, code)
        local name = OP_CODE[(code & 0x7F) + 1]
        local f = "R[%s] = R[%s][K[%s]]"
        local A = Bytedump:A(code)
        local B = Bytedump:B(code)
        local C = Bytedump:C(code)
        print(index, name, getMode(code), string.format(f, A, B, C))
    end,
    OP_SETTABUP = function(index, code)
        local f = "UpValue[%s][K[%s]] = R[%s]"
        local name = OP_CODE[(code & 0x7F) + 1]
        local A = Bytedump:A(code)
        local B = Bytedump:B(code)
        local C = Bytedump:C(code)
        local k = Bytedump:k(code)
        if k == 1 then
            f = "UpValue[%s][K[%s]] = K[%s]"
        end
        print(index, name, getMode(code), string.format(f, A, B, C))
    end,
    OP_SETTABLE = function(index, code)
        -- R[A][R[B]] := RK(C)
        local f = "R[%s][R[%s]] = R[%s]"
        local name = OP_CODE[(code & 0x7F) + 1]
        local A = Bytedump:A(code)
        local B = Bytedump:B(code)
        local C = Bytedump:C(code)
        local k = Bytedump:k(code)
        if k == 1 then
            f = "R[%s][R[%s]] = K[%s]"
        end
        print(index, name, getMode(code), string.format(f, A, B, C))
    end,
    OP_SETI = function(index, code)
        local f = "R[%s][%s] = R[%s]"
        local name = OP_CODE[(code & 0x7F) + 1]
        local A = Bytedump:A(code)
        local B = Bytedump:B(code)
        local C = Bytedump:C(code)
        local k = Bytedump:k(code)
        if k == 1 then
            f = "R[%s][%s] = K[%s]"
        end
        print(index, name, "", getMode(code), string.format(f, A, B, C))
    end,
    OP_SETFIELD = function(index, code)
        local f = "R[%s][K[%s]] = R[%s]"
        local name = OP_CODE[(code & 0x7F) + 1]
        local A = Bytedump:A(code)
        local B = Bytedump:B(code)
        local C = Bytedump:C(code)
        local k = Bytedump:k(code)
        if k == 1 then
            f = "R[%s][K[%s]] = K[%s]"
        end
        print(index, name, getMode(code), string.format(f, A, B, C))
    end,
    OP_NEWTABLE = function(index, code)
        local f = "R[%s] = { hash * B:%s , array * C:%s} k = %s"
        local name = OP_CODE[(code & 0x7F) + 1]
        local A = Bytedump:A(code)
        local B = Bytedump:B(code)
        local C = Bytedump:C(code)
        local k = Bytedump:k(code)
        print(index, name, getMode(code), string.format(f, A, B, C, k))
    end,
    OP_SELF = function(index, code)
        -- R[A+1] := R[B]; R[A] := R[B][RK(C):string]
        local f = "R[%s] = R[%s]; R[%s] = R[%s]R[%s]"
        local name = OP_CODE[(code & 0x7F) + 1]
        local A = Bytedump:A(code)
        local B = Bytedump:B(code)
        local C = Bytedump:C(code)
        local k = Bytedump:k(code)
        if k == 1 then
            f = "R[%s] = R[%s]; R[%s] = R[%s]K[%s]"
        end
        print(index, name, "", getMode(code), string.format(f, A + 1, B, A, B, C))
    end,
    OP_ADDI = function(index, code)
        local name = OP_CODE[(code & 0x7F) + 1]
        local f = "R[%s] = R[%s] + sC:%s and jump to %s"
        local A = Bytedump:A(code)
        local B = Bytedump:B(code)
        local sC = Bytedump:sC(code)
        print(index, name, "", getMode(code), string.format(f, A, B, sC, index + 2))
    end,
    OP_ADDK = function(index, code)
        -- R[A] = R[B] + K[C]:number; pc++
        local name = OP_CODE[(code & 0x7F) + 1]
        local f = "R[%s] = R[%s] + K[%s] and jump to %s"
        local A = Bytedump:A(code)
        local B = Bytedump:B(code)
        local C = Bytedump:C(code)
        print(index, name, "", getMode(code), string.format(f, A, B, C, index + 2))
    end,
    OP_SUBK = function(index, code)
        -- R[A] = R[B] - K[C]:number; pc++
        local name = OP_CODE[(code & 0x7F) + 1]
        local f = "R[%s] = R[%s] - K[%s] and jump to %s"
        local A = Bytedump:A(code)
        local B = Bytedump:B(code)
        local C = Bytedump:C(code)
        print(index, name, "", getMode(code), string.format(f, A, B, C, index + 2))
    end,
    OP_MULK = function(index, code)
        -- R[A] = R[B] * K[C]:number; pc++
        local name = OP_CODE[(code & 0x7F) + 1]
        local f = "R[%s] = R[%s] * K[%s] and jump to %s"
        local A = Bytedump:A(code)
        local B = Bytedump:B(code)
        local C = Bytedump:C(code)
        print(index, name, "", getMode(code), string.format(f, A, B, C, index + 2))
    end,
    OP_MODK = function(index, code)
        -- R[A] = R[B] % K[C]:number; pc++
        local name = OP_CODE[(code & 0x7F) + 1]
        local f = "R[%s] = R[%s] %% K[%s] and jump to %s"
        local A = Bytedump:A(code)
        local B = Bytedump:B(code)
        local C = Bytedump:C(code)
        print(index, name, "", getMode(code), string.format(f, A, B, C, index + 2))
    end,
    OP_POWK = function(index, code)
        -- R[A] = R[B] ^ K[C]:number; pc++
        local name = OP_CODE[(code & 0x7F) + 1]
        local f = "R[%s] = R[%s] ^ K[%s] and jump to %s"
        local A = Bytedump:A(code)
        local B = Bytedump:B(code)
        local C = Bytedump:C(code)
        print(index, name, "", getMode(code), string.format(f, A, B, C, index + 2))
    end,
    OP_DIVK = function(index, code)
        -- R[A] = R[B] / K[C]:number; pc++
        local name = OP_CODE[(code & 0x7F) + 1]
        local f = "R[%s] = R[%s] / K[%s] and jump to %s"
        local A = Bytedump:A(code)
        local B = Bytedump:B(code)
        local C = Bytedump:C(code)
        print(index, name, "", getMode(code), string.format(f, A, B, C, index + 2))
    end,
    OP_IDIVK = function(index, code)
        -- R[A] = R[B] // K[C]:number; pc++
        local name = OP_CODE[(code & 0x7F) + 1]
        local f = "R[%s] = R[%s] // K[%s] and jump to %s"
        local A = Bytedump:A(code)
        local B = Bytedump:B(code)
        local C = Bytedump:C(code)
        print(index, name, getMode(code), string.format(f, A, B, C, index + 2))
    end,
    OP_BANDK = function(index, code)
        -- R[A] = R[B] & K[C]:integer; pc++
        local name = OP_CODE[(code & 0x7F) + 1]
        local f = "R[%s] = R[%s] & K[%s] and jump to %s"
        local A = Bytedump:A(code)
        local B = Bytedump:B(code)
        local C = Bytedump:C(code)
        print(index, name, getMode(code), string.format(f, A, B, C, index + 2))
    end,
    OP_BORK = function(index, code)
        -- R[A] = R[B] | K[C]:integer; pc++
        local name = OP_CODE[(code & 0x7F) + 1]
        local f = "R[%s] = R[%s] | K[%s] and jump to %s"
        local A = Bytedump:A(code)
        local B = Bytedump:B(code)
        local C = Bytedump:C(code)
        print(index, name, "", getMode(code), string.format(f, A, B, C, index + 2))
    end,
    OP_BXORK = function(index, code)
        -- R[A] = R[B] ~ K[C]:integer; pc++
        local name = OP_CODE[(code & 0x7F) + 1]
        local f = "R[%s] = R[%s] xor K[%s] and jump to %s"
        local A = Bytedump:A(code)
        local B = Bytedump:B(code)
        local C = Bytedump:C(code)
        print(index, name, getMode(code), string.format(f, A, B, C, index + 2))
    end,
    OP_SHRI = function(index, code)
        -- R[A] = R[B] >> sC; pc++
        local name = OP_CODE[(code & 0x7F) + 1]
        local f = "R[%s] = R[%s] >> -(sC:%s) and jump to %s"
        local A = Bytedump:A(code)
        local B = Bytedump:B(code)
        local sC = Bytedump:sC(code)
        print(index, name, "", getMode(code), string.format(f, A, B, sC, index + 2))
    end,
    OP_SHLI = function(index, code)
        -- R[A] = sC << R[B]; pc++
        local name = OP_CODE[(code & 0x7F) + 1]
        local f = "R[%s] = (sC:%s) << R[%s] and jump to %s"
        local A = Bytedump:A(code)
        local B = Bytedump:B(code)
        local sC = Bytedump:sC(code)
        print(index, name, "", getMode(code), string.format(f, A, sC, B, index + 2))
    end,
    OP_ADD = function(index, code)
        local name = OP_CODE[(code & 0x7F) + 1]
        local f = "R[%s] = R[%s] + R[%s] and jump to %s"
        local A = Bytedump:A(code)
        local B = Bytedump:B(code)
        local C = Bytedump:C(code)
        print(index, name, "", getMode(code), string.format(f, A, B, C, index + 2))
    end,
    OP_SUB = function(index, code)
        local name = OP_CODE[(code & 0x7F) + 1]
        local f = "R[%s] = R[%s] - R[%s] and jump to %s"
        local A = Bytedump:A(code)
        local B = Bytedump:B(code)
        local C = Bytedump:C(code)
        print(index, name, "", getMode(code), string.format(f, A, B, C, index + 2))
    end,
    OP_MUL = function(index, code)
        -- R[A] = R[B] * R[C]; pc++
        local name = OP_CODE[(code & 0x7F) + 1]
        local f = "R[%s] = R[%s] * R[%s] and jump to %s"
        local A = Bytedump:A(code)
        local B = Bytedump:B(code)
        local C = Bytedump:C(code)
        print(index, name, "", getMode(code), string.format(f, A, B, C, index + 2))
    end,
    OP_MOD = function(index, code)
        -- R[A] = R[B] % R[C]; pc++
        local name = OP_CODE[(code & 0x7F) + 1]
        local f = "R[%s] = R[%s] %% R[%s] and jump to %s"
        local A = Bytedump:A(code)
        local B = Bytedump:B(code)
        local C = Bytedump:C(code)
        print(index, name, "", getMode(code), string.format(f, A, B, C, index + 2))
    end,
    OP_POW = function(index, code)
        -- R[A] = R[B] ^ R[C]; pc++
        local name = OP_CODE[(code & 0x7F) + 1]
        local f = "R[%s] = R[%s] ^ R[%s] and jump to %s"
        local A = Bytedump:A(code)
        local B = Bytedump:B(code)
        local C = Bytedump:C(code)
        print(index, name, "", getMode(code), string.format(f, A, B, C, index + 2))
    end,
    OP_DIV = function(index, code)
        -- // R[A] = R[B] / R[C]; pc++
        local name = OP_CODE[(code & 0x7F) + 1]
        local f = "R[%s] = R[%s] / R[%s] and jump to %s"
        local A = Bytedump:A(code)
        local B = Bytedump:B(code)
        local C = Bytedump:C(code)
        print(index, name, "", getMode(code), string.format(f, A, B, C, index + 2))
    end,
    OP_IDIV = function(index, code)
        -- R[A] = R[B] // R[C]; pc++
        local name = OP_CODE[(code & 0x7F) + 1]
        local f = "R[%s] = R[%s] // R[%s] and jump to %s"
        local A = Bytedump:A(code)
        local B = Bytedump:B(code)
        local C = Bytedump:C(code)
        print(index, name, "", getMode(code), string.format(f, A, B, C, index + 2))
    end,
    OP_BAND = function(index, code)
        --  R[A] = R[B] & R[C]; pc++
        local name = OP_CODE[(code & 0x7F) + 1]
        local f = "R[%s] = R[%s] & R[%s] and jump to %s"
        local A = Bytedump:A(code)
        local B = Bytedump:B(code)
        local C = Bytedump:C(code)
        print(index, name, "", getMode(code), string.format(f, A, B, C, index + 2))
    end,
    OP_BOR = function(index, code)
        -- R[A] = R[B] | R[C]; pc++
        local name = OP_CODE[(code & 0x7F) + 1]
        local f = "R[%s] = R[%s] | R[%s] and jump to %s"
        local A = Bytedump:A(code)
        local B = Bytedump:B(code)
        local C = Bytedump:C(code)
        print(index, name, "", getMode(code), string.format(f, A, B, C, index + 2))
    end,
    OP_BXOR = function(index, code)
        -- R[A] = R[B] ~ R[C]; pc++
        local name = OP_CODE[(code & 0x7F) + 1]
        local f = "R[%s] = R[%s] ~ R[%s] and jump to %s"
        local A = Bytedump:A(code)
        local B = Bytedump:B(code)
        local C = Bytedump:C(code)
        print(index, name, "", getMode(code), string.format(f, A, B, C, index + 2))
    end,
    OP_SHL = function(index, code)
        -- R[A] = R[B] << R[C]; pc++
        local name = OP_CODE[(code & 0x7F) + 1]
        local f = "R[%s] = R[%s] << R[%s] and jump to %s"
        local A = Bytedump:A(code)
        local B = Bytedump:B(code)
        local C = Bytedump:C(code)
        print(index, name, "", getMode(code), string.format(f, A, B, C, index + 2))
    end,
    OP_SHR = function(index, code)
        local name = OP_CODE[(code & 0x7F) + 1]
        local f = "R[%s] = R[%s] >> R[%s] and jump to %s"
        local A = Bytedump:A(code)
        local B = Bytedump:B(code)
        local C = Bytedump:C(code)
        print(index, name, "", getMode(code), string.format(f, A, B, C, index + 2))
    end,
    OP_MMBIN = function(index, code)
        local name = OP_CODE[(code & 0x7F) + 1]
        local f = "R[%s] = call R[%s] or R[%s] %s"
        local oA = Bytedump:A(Bytedump.codes[index - 1])
        local A = Bytedump:A(code)
        local B = Bytedump:B(code)
        local C = Bytedump:C(code) -- lua need add 1 to adopt c
        print(index, name, getMode(code), string.format(f, oA, A, B, TM[C + 1]))
    end,
    OP_MMBINI = function(index, code)
        local name = OP_CODE[(code & 0x7F) + 1]
        local f = "R[%s] = call R[%s] or sB:%s %s"
        local oA = Bytedump:A(Bytedump.codes[index - 1])
        local A = Bytedump:A(code)
        local sB = Bytedump:sB(code)
        local k = Bytedump:k(code)
        local C = Bytedump:C(code) -- lua need add 1 to adopt c
        if k == 0 then
            print(index, name, getMode(code), string.format(f, oA, A, sB, TM[C + 1]))
        else
            f = "R[%s] = call sB:%s or R[%s] %s"
            print(index, name, getMode(code), string.format(f, oA, sB, A, TM[C + 1]))
        end
    end,
    OP_MMBINK = function(index, code)
        local name = OP_CODE[(code & 0x7F) + 1]
        local f = "R[%s] = call R[%s] or K[%s] %s"
        local oA = Bytedump:A(Bytedump.codes[index - 1])
        local A = Bytedump:A(code)
        local B = Bytedump:B(code)
        local k = Bytedump:k(code)
        local C = Bytedump:C(code) -- lua need add 1 to adopt c
        if k == 0 then
            print(index, name, getMode(code), string.format(f, oA, A, B, TM[C + 1]))
        else
            f = "R[%s] = call K[%s] or R[%s] %s"
            print(index, name, getMode(code), string.format(f, oA, B, A, TM[C + 1]))
        end
    end,
    OP_UNM = function(index, code)
        -- R[A] := -R[B]
        local name = OP_CODE[(code & 0x7F) + 1]
        local f = "R[%s] = -R[%s]"
        local A = Bytedump:A(code)
        local B = Bytedump:B(code)
        print(index, name, "", getMode(code), string.format(f, A, B))
    end,
    OP_BNOT = function(index, code)
        -- R[A] := ~R[B]
        local name = OP_CODE[(code & 0x7F) + 1]
        local f = "R[%s] = ~R[%s]"
        local A = Bytedump:A(code)
        local B = Bytedump:B(code)
        print(index, name, "", getMode(code), string.format(f, A, B))
    end,
    OP_NOT = function(index, code)
        -- R[A] := not R[B]
        local name = OP_CODE[(code & 0x7F) + 1]
        local f = "R[%s] = not R[%s]"
        local A = Bytedump:A(code)
        local B = Bytedump:B(code)
        print(index, name, "", getMode(code), string.format(f, A, B))
    end,
    OP_LEN = function(index, code)
        -- R[A] := #R[B]
        local name = OP_CODE[(code & 0x7F) + 1]
        local f = "R[%s] = #R[%s]"
        local A = Bytedump:A(code)
        local B = Bytedump:B(code)
        print(index, name, "", getMode(code), string.format(f, A, B))
    end,
    OP_CONCAT = function(index, code)
        -- // R[A] := R[A].. ... ..R[A + B - 1]
        local f = "for i = 1 to B:%s - 1 then  R[%s] == R[%s] .. R[%s + i]"
        local name = OP_CODE[(code & 0x7F) + 1]
        local A = Bytedump:A(code)
        local B = Bytedump:B(code)
        print(index, name, getMode(code), string.format(f, B, A, A, A))
    end,
    OP_CLOSE = function(index, code)
        local f = "close upvalues >= level:%s"
        local name = OP_CODE[(code & 0x7F) + 1]
        local A = Bytedump:A(code)
        print(index, name, getMode(code), string.format(f, A))
    end,
    OP_TBC = nil,
    OP_JMP = function(index, code)
        local f = "jump to %s"
        local name = OP_CODE[(code & 0x7F) + 1]
        local sJ = Bytedump:sJ(code)
        print(index, name, "", getMode(code), string.format(f, index + sJ + 1))
    end,
    OP_EQ = function(index, code)
        local f = "if (R[%s] == R[%s]) != %s then goto %s"
        local name = OP_CODE[(code & 0x7F) + 1]
        local A = Bytedump:A(code)
        local B = Bytedump:B(code)
        local k = Bytedump:k(code)
        print(index, name, "", getMode(code), string.format(f, A, B, k, index + 2))
    end,
    OP_LT = function(index, code)
        local f = "if (R[%s] < R[%s]) != %s then goto %s"
        local name = OP_CODE[(code & 0x7F) + 1]
        local A = Bytedump:A(code)
        local B = Bytedump:B(code)
        local k = Bytedump:k(code)
        print(index, name, "", getMode(code), string.format(f, A, B, k, index + 2))
    end,
    OP_LE = function(index, code)
        local f = "if (R[%s] <= R[%s]) != %s then goto %s"
        local name = OP_CODE[(code & 0x7F) + 1]
        local A = Bytedump:A(code)
        local B = Bytedump:B(code)
        local k = Bytedump:k(code)
        print(index, name, "", getMode(code), string.format(f, A, B, k, index + 2))
    end,
    OP_EQK = function(index, code)
        -- if ((R[A] == K[B]) ~= k) then pc++
        local f = "if R[%s] == K[%s]) != %s then goto %s"
        local name = OP_CODE[(code & 0x7F) + 1]
        local A = Bytedump:A(code)
        local B = Bytedump:B(code)
        local k = Bytedump:k(code)
        print(index, name, "", getMode(code), string.format(f, A, B, k, index + 2))
    end,
    OP_EQI = function(index, code)
        local name = OP_CODE[(code & 0x7F) + 1]
        local f = "if (R[%s] == sB:%s) != %s goto %s else goto %s"
        local A = Bytedump:A(code)
        local k = Bytedump:k(code)
        local sB = Bytedump:sB(code)
        local sJ = Bytedump:sJ(Bytedump.codes[index + 1])
        print(index, name, "", getMode(code), string.format(f, A, sB, k, index + 2, index + sJ + 2))
    end,
    OP_LTI = function(index, code)
        -- if ((R[A] < sB) ~= k) then pc++
        local name = OP_CODE[(code & 0x7F) + 1]
        local f = "if (R[%s] < sB:%s) != %s goto %s"
        local A = Bytedump:A(code)
        local k = Bytedump:k(code)
        local sB = Bytedump:sB(code)
        print(index, name, "", getMode(code), string.format(f, A, sB, k, index + 2))
    end,
    OP_LEI = function(index, code)
        -- if ((R[A] <= sB) ~= k) then pc++
        local name = OP_CODE[(code & 0x7F) + 1]
        local f = "if (R[%s] <= sB:%s) != %s goto %s else goto %s"
        local A = Bytedump:A(code)
        local k = Bytedump:k(code)
        local sB = Bytedump:sB(code)
        local sJ = Bytedump:sJ(Bytedump.codes[index + 1])
        print(index, name, "", getMode(code), string.format(f, A, sB, k, index + 2, index + sJ + 2))
    end,
    OP_GTI = function(index, code)
        local name = OP_CODE[(code & 0x7F) + 1]
        local f = "if (R[%s] > sB:%s) == %s goto %s"
        local A = Bytedump:A(code)
        local k = Bytedump:k(code)
        local sB = Bytedump:sB(code)
        print(index, name, "", getMode(code), string.format(f, A, sB, k, index + 2))
    end,
    OP_GEI = function(index, code)
        -- if ((R[A] >= sB) ~= k) then pc++
        local name = OP_CODE[(code & 0x7F) + 1]
        local f = "if (R[%s] >= sB:%s) != %s goto %s else goto %s"
        local A = Bytedump:A(code)
        local k = Bytedump:k(code)
        local sB = Bytedump:sB(code)
        local sJ = Bytedump:sJ(Bytedump.codes[index + 1])
        print(index, name, "", getMode(code), string.format(f, A, sB, k, index + 2, index + sJ + 2))
    end,
    OP_TEST = function(index, code)
        local f = "if bool(R[%s]) == %s goto %s"
        local name = OP_CODE[(code & 0x7F) + 1]
        local A = Bytedump:A(code)
        local k = Bytedump:k(code)
        print(index, name, "", getMode(code), string.format(f, A, k, index + 2))
    end,
    OP_TESTSET = function(index, code)
        -- if (not R[B] == k) then pc++ else R[A] := R[B]
        local f = "if not R[%s] == %s goto %s else R[%s] = R[%s]"
        local name = OP_CODE[(code & 0x7F) + 1]
        local A = Bytedump:A(code)
        local k = Bytedump:k(code)
        local B = Bytedump:B(code)
        print(index, name, getMode(code), string.format(f, B, k, index + 2, A, B))
    end,
    OP_CALL = function(index, code)
        local f = "R[%s](arg * %s) {return * (C:%s - 1)}"
        local name = OP_CODE[(code & 0x7F) + 1]
        local A = Bytedump:A(code)
        local B = Bytedump:B(code)
        local C = Bytedump:C(code)
        local nargs = B - 1
        if B == 0 then
            nargs = "B:0 call another func"
        end
        print(index, name, "", getMode(code), string.format(f, A, nargs, C))
    end,
    OP_TAILCALL = nil,
    OP_RETURN = function(index, code)
        local n = Bytedump:B(code) - 1
        local f = "back to caller"
        if n < 0 then
            f = f .. " with mul multiple return"
        else
            f = f .. " with " .. n .. " return"
        end
        local name = OP_CODE[(code & 0x7F) + 1]
        print(index, name, getMode(code), f)
    end,
    OP_RETURN0 = function(index, code)
        local f = "back to caller"
        local name = OP_CODE[(code & 0x7F) + 1]
        print(index, name, getMode(code), f)
    end,
    OP_RETURN1 = function(index, code)
        local f = "return R[%s], back to caller"
        local name = OP_CODE[(code & 0x7F) + 1]
        local A = Bytedump:A(code)
        print(index, name, getMode(code), string.format(f, A))
    end,
    OP_FORLOOP = function(index, code)
        local f = "for i = R[%s], R[%s], R[%s] then t = R[%s] + R[%s], R[%s] = t, R[%s] = t and goto %s else goto %s"
        local name = OP_CODE[(code & 0x7F) + 1]
        local A = Bytedump:A(code)
        local Bx = Bytedump:Bx(code)
        print(index, name,
            getMode(code), string.format(f, A, A + 1, A + 2, A, A + 2, A, A + 3, index - Bx + 1, index + 1))
    end,
    OP_FORPREP = function(index, code)
        local f = "for i = R[%s], R[%s], R[%s] then R[%s] = R[%s] if R[%s] <= R[%s] goto %s else goto %s"
        local name = OP_CODE[(code & 0x7F) + 1]
        local A = Bytedump:A(code)
        local Bx = Bytedump:Bx(code)
        print(index, name,
            getMode(code), string.format(f, A, A + 1, A + 2, A + 3, A, A, A + 1, index + 1, index + Bx + 2))
    end,
    OP_TFORPREP = nil,
    OP_TFORCALL = nil,
    OP_TFORLOOP = nil,
    OP_SETLIST = function(index, code)
        local f = "for i = 1 to %s then R[%s][%s + i] = R[%s + i]"
        local name = OP_CODE[(code & 0x7F) + 1]
        local A = Bytedump:A(code)
        local B = Bytedump:B(code)
        local C = Bytedump:C(code)
        print(index, name, getMode(code), string.format(f, B, A, C, A))
    end,
    OP_CLOSURE = function(index, code)
        local f = "R[%s] = closure(P[%s])"
        local name = OP_CODE[(code & 0x7F) + 1]
        local A = Bytedump:A(code)
        local Bx = Bytedump:Bx(code)
        print(index, name, getMode(code), string.format(f, A, Bx))
    end,
    OP_VARARG = function(index, code)
        -- // R[A], R[A+1], ..., R[A+C-2] = vararg
        -- int n = GETARG_C(i) - 1;--required results
        --Protect(luaT_getvarargs(L, ci, ra, n));
        local f = "for i = 0 to C:%s -2 then R[%s+i] = arsg[i]"
        local name = OP_CODE[(code & 0x7F) + 1]
        local A = Bytedump:A(code)
        local C = Bytedump:C(code)
        if C == 0 then
            print(index, name, getMode(code), "get all varargs")
        else
            print(index, name, getMode(code), string.format(f, C, A))
        end
    end,
    OP_VARARGPREP = function(index, code)
        local f = "fixed args number: A:%s"
        local name = OP_CODE[(code & 0x7F) + 1]
        local A = Bytedump:A(code)
        print(index, name, getMode(code), string.format(f, A))
    end,
    OP_EXTRAARG = nil,
}


function Bytedump:sBx(code)
    return ((code & self.Bx_mask) >> self.sBx_pos) - self.sBx_offset
end

function Bytedump:A(code)
    return (code & self.A_mask) >> self.A_pos
end

function Bytedump:B(code)
    return (code & self.B_mask) >> self.B_pos
end

function Bytedump:sB(code)
    return ((code & self.sB_mask) >> self.sB_pos) - self.sB_offset
end

function Bytedump:Bx(code)
    return (code & self.Bx_mask) >> self.Bx_pos
end

function Bytedump:C(code)
    return (code & self.C_mask) >> self.C_pos
end

function Bytedump:sC(code)
    return ((code & self.sC_mask) >> self.sC_pos) - self.sC_offset
end

function Bytedump:k(code)
    return (code & self.k_mask) >> self.k_pos
end

function Bytedump:sJ(code)
    return ((code & self.sJ_mask) >> self.sJ_pos) - self.sJ_offset
end

function Bytedump:dump(file)
    print(file.script_name)
    self.codes = file.instructions

    for index, code in pairs(self.codes) do
        local act = OP_CODE[(code & 0x7F) + 1]
        if OP_ACT[act] then
            OP_ACT[act](index, code)
        else
            print(index, act)
        end
    end
end
