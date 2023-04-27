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

local OP_ACT = {
    OP_MOVE = function(index, code)
        local f = "R[%s] = R[%s]"
        local name = OP_CODE[(code & 0x7F) + 1]
        local B = Bytedump:B(code)
        local A = Bytedump:A(code)
        print(index, name, "", string.format(f, A, B))
    end,
    OP_LOADI = function(index, code)
        local f = "R[%s] = sBx:%s"
        local name = OP_CODE[(code & 0x7F) + 1]
        local sBx = Bytedump:sBx(code)
        local A = Bytedump:A(code)
        print(index, name, string.format(f, A, sBx))
    end,
    OP_LOADF = function(index, code)
        local f = "R[%s] = (double)sBx:%s"
        local name = OP_CODE[(code & 0x7F) + 1]
        local sBx = Bytedump:sBx(code)
        local A = Bytedump:A(code)
        print(index, name, string.format(f, A, sBx))
    end,
    OP_LOADK = function(index, code)
        local f = "R[%s] = K[%s]"
        local name = OP_CODE[(code & 0x7F) + 1]
        local A = Bytedump:A(code)
        local Bx = Bytedump:Bx(code)
        print(index, name, string.format(f, A, Bx))
    end,
    OP_LOADKX = nil, -- 常量个数大于 2^17 -1 之后, 才会用到这个指令
    OP_LOADFALSE = function(index, code)
        local f = "R[%s] = false"
        local name = OP_CODE[(code & 0x7F) + 1]
        local A = Bytedump:A(code)
        print(index, name, string.format(f, A))
    end,
    OP_LFALSESKIP = function(index, code)
        local f = "R[%s] = false goto %s"
        local name = OP_CODE[(code & 0x7F) + 1]
        local A = Bytedump:A(code)
        print(index, name, string.format(f, A, index + 2))
    end,
    OP_LOADTRUE = function(index, code)
        local f = "R[%s] = true"
        local name = OP_CODE[(code & 0x7F) + 1]
        local A = Bytedump:A(code)
        print(index, name, string.format(f, A))
    end,
    OP_LOADNIL = function(index, code)
        -- R[A], R[A+1], ..., R[A+B] := nil
        local f = "for i = 0 to %s then R[%s+i] = nil"
        local name = OP_CODE[(code & 0x7F) + 1]
        local A = Bytedump:A(code)
        local B = Bytedump:B(code)
        print(index, name, string.format(f, B, A))
    end,
    OP_GETUPVAL = nil,
    OP_SETUPVAL = nil,
    OP_GETTABUP = function(index, code)
        local f = "R[%s] = UpValue[%s][K[%s]]"
        local name = OP_CODE[(code & 0x7F) + 1]
        local A = Bytedump:A(code)
        local B = Bytedump:B(code)
        local C = Bytedump:C(code)
        print(index, name, string.format(f, A, B, C))
    end,
    OP_GETTABLE = nil,
    OP_GETI = function(index, code)
        local name = OP_CODE[(code & 0x7F) + 1]
        local f = "R[%s] = R[%s][C:%s]"
        local A = Bytedump:A(code)
        local B = Bytedump:B(code)
        local C = Bytedump:C(code)
        print(index, name, "", string.format(f, A, B, C))
    end,
    OP_GETFIELD = function(index, code)
        local name = OP_CODE[(code & 0x7F) + 1]
        local f = "R[%s] = R[%s][K[%s]]"
        local A = Bytedump:A(code)
        local B = Bytedump:B(code)
        local C = Bytedump:C(code)
        print(index, name, string.format(f, A, B, C))
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
        print(index, name, string.format(f, A, B, C))
    end,
    OP_SETTABLE = nil,
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
        print(index, name, "", string.format(f, A, B, C))
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
        print(index, name, string.format(f, A, B, C))
    end,
    OP_NEWTABLE = function(index, code)
        local f = "R[%s] = { hash * B:%s , array * C:%s} k = %s"
        local name = OP_CODE[(code & 0x7F) + 1]
        local A = Bytedump:A(code)
        local B = Bytedump:B(code)
        local C = Bytedump:C(code)
        local k = Bytedump:k(code)
        print(index, name, string.format(f, A, B, C, k))
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
        print(index, name, "", string.format(f, A + 1, B, A, B, C))
    end,
    OP_ADDI = function(index, code)
        local name = OP_CODE[(code & 0x7F) + 1]
        local f = "R[%s] = R[%s] + sC:%s and jump to %s"
        local A = Bytedump:A(code)
        local B = Bytedump:B(code)
        local sC = Bytedump:sC(code)
        print(index, name, "", string.format(f, A, B, sC, index + 2))
    end,
    OP_ADDK = nil,
    OP_SUBK = function(index, code)
        -- R[A] = R[B] - K[C]:number; pc++
        local name = OP_CODE[(code & 0x7F) + 1]
        local f = "R[%s] = R[%s] + K[%s] and jump to %s"
        local A = Bytedump:A(code)
        local B = Bytedump:B(code)
        local C = Bytedump:C(code)
        print(index, name, "", string.format(f, A, B, C, index + 2))
    end,
    OP_MULK = function(index, code)
        -- R[A] = R[B] * K[C]:number; pc++
        local name = OP_CODE[(code & 0x7F) + 1]
        local f = "R[%s] = R[%s] * K[%s] and jump to %s"
        local A = Bytedump:A(code)
        local B = Bytedump:B(code)
        local C = Bytedump:C(code)
        print(index, name, "", string.format(f, A, B, C, index + 2))
    end,
    OP_MODK = function(index, code)
        -- R[A] = R[B] % K[C]:number; pc++
        local name = OP_CODE[(code & 0x7F) + 1]
        local f = "R[%s] = R[%s] %% K[%s] and jump to %s"
        local A = Bytedump:A(code)
        local B = Bytedump:B(code)
        local C = Bytedump:C(code)
        print(index, name, "", string.format(f, A, B, C, index + 2))
    end,
    OP_POWK = nil,
    OP_DIVK = function(index, code)
        -- R[A] = R[B] / K[C]:number; pc++
        local name = OP_CODE[(code & 0x7F) + 1]
        local f = "R[%s] = R[%s] / K[%s] and jump to %s"
        local A = Bytedump:A(code)
        local B = Bytedump:B(code)
        local C = Bytedump:C(code)
        print(index, name, "", string.format(f, A, B, C, index + 2))
    end,
    OP_IDIVK = nil,
    OP_BANDK = nil,
    OP_BORK = nil,
    OP_BXORK = function(index, code)
        -- R[A] = R[B] ~ K[C]:integer; pc++
        local name = OP_CODE[(code & 0x7F) + 1]
        local f = "R[%s] = R[%s] xor K[%s] and jump to %s"
        local A = Bytedump:A(code)
        local B = Bytedump:B(code)
        local C = Bytedump:C(code)
        print(index, name, string.format(f, A, B, C, index + 2))
    end,
    OP_SHRI = function(index, code)
        -- R[A] = R[B] >> sC; pc++
        local name = OP_CODE[(code & 0x7F) + 1]
        local f = "R[%s] = R[%s] >> -(sC:%s) and jump to %s"
        local A = Bytedump:A(code)
        local B = Bytedump:B(code)
        local sC = Bytedump:sC(code)
        print(index, name, "", string.format(f, A, B, sC, index + 2))
    end,
    OP_SHLI = nil,
    OP_ADD = function(index, code)
        local name = OP_CODE[(code & 0x7F) + 1]
        local f = "R[%s] = R[%s] + R[%s] and jump to %s"
        local A = Bytedump:A(code)
        local B = Bytedump:B(code)
        local C = Bytedump:C(code)
        print(index, name, "", string.format(f, A, B, C, index + 2))
    end,
    OP_SUB = function(index, code)
        local name = OP_CODE[(code & 0x7F) + 1]
        local f = "R[%s] = R[%s] - R[%s] and jump to %s"
        local A = Bytedump:A(code)
        local B = Bytedump:B(code)
        local C = Bytedump:C(code)
        print(index, name, "", string.format(f, A, B, C, index + 2))
    end,
    OP_MUL = nil,
    OP_MOD = nil,
    OP_POW = nil,
    OP_DIV = nil,
    OP_IDIV = nil,
    OP_BAND = nil,
    OP_BOR = nil,
    OP_BXOR = nil,
    OP_SHL = nil,
    OP_SHR = nil,
    OP_MMBIN = nil,
    OP_MMBINI = nil,
    OP_MMBINK = nil,
    OP_UNM = nil,
    OP_BNOT = nil,
    OP_NOT = nil,
    OP_LEN = nil,
    OP_CONCAT = nil,
    OP_CLOSE = nil,
    OP_TBC = nil,
    OP_JMP = function(index, code)
        local f = "jump to %s"
        local name = OP_CODE[(code & 0x7F) + 1]
        local sJ = Bytedump:sJ(code)
        print(index, name, "", string.format(f, index + sJ + 1))
    end,
    OP_EQ = function(index, code)
        local f = "if R[%s] == R[%s]) != %s then goto %s"
        local name = OP_CODE[(code & 0x7F) + 1]
        local A = Bytedump:A(code)
        local B = Bytedump:B(code)
        local k = Bytedump:k(code)
        print(index, name, "", string.format(f, A, B, k, index + 2))
    end,
    OP_LT = function(index, code)
        local f = "if R[%s] < R[%s]) != %s then goto %s"
        local name = OP_CODE[(code & 0x7F) + 1]
        local A = Bytedump:A(code)
        local B = Bytedump:B(code)
        local k = Bytedump:k(code)
        print(index, name, "", string.format(f, A, B, k, index + 2))
    end,
    OP_LE = function(index, code)
        local f = "if R[%s] <= R[%s]) != %s then goto %s"
        local name = OP_CODE[(code & 0x7F) + 1]
        local A = Bytedump:A(code)
        local B = Bytedump:B(code)
        local k = Bytedump:k(code)
        print(index, name, "", string.format(f, A, B, k, index + 2))
    end,
    OP_EQK = nil,
    OP_EQI = function(index, code)
        local name = OP_CODE[(code & 0x7F) + 1]
        local f = "if (R[%s] == sB:%s) != %s goto %s else goto %s"
        local A = Bytedump:A(code)
        local k = Bytedump:k(code)
        local sB = Bytedump:sB(code)
        local sJ = Bytedump:sJ(Bytedump.codes[index + 1])
        print(index, name, "", string.format(f, A, sB, k, index + 2, index + sJ + 2))
    end,
    OP_LTI = nil,
    OP_LEI = function(index, code)
        -- if ((R[A] <= sB) ~= k) then pc++
        local name = OP_CODE[(code & 0x7F) + 1]
        local f = "if (R[%s] <= sB:%s) != %s goto %s else goto %s"
        local A = Bytedump:A(code)
        local k = Bytedump:k(code)
        local sB = Bytedump:sB(code)
        local sJ = Bytedump:sJ(Bytedump.codes[index + 1])
        print(index, name, "", string.format(f, A, sB, k, index + 2, index + sJ + 2))
    end,
    OP_GTI = function(index, code)
        local name = OP_CODE[(code & 0x7F) + 1]
        local f = "if (R[%s] > sB:%s) == %s goto %s else goto %s"
        local A = Bytedump:A(code)
        local k = Bytedump:k(code)
        local sB = Bytedump:sB(code)
        local sJ = Bytedump:sJ(Bytedump.codes[index + 1])
        print(index, name, "", string.format(f, A, sB, k, index + 2, index + sJ + 2))
    end,
    OP_GEI = nil,
    OP_TEST = function(index, code)
        local f = "if bool(R[%s]) == %s goto %s else goto %s"
        local name = OP_CODE[(code & 0x7F) + 1]
        local A = Bytedump:A(code)
        local k = Bytedump:k(code)
        local sJ = Bytedump:sJ(Bytedump.codes[index + 1])
        print(index, name, "", string.format(f, A, k, index + 2, index + sJ + 2))
    end,
    OP_TESTSET = nil,
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
        print(index, name, "", string.format(f, A, nargs, C))
    end,
    OP_TAILCALL = nil,
    OP_RETURN = nil,
    OP_RETURN0 = nil,
    OP_RETURN1 = nil,
    OP_FORLOOP = function(index, code)
        local f = "for i = R[%s], R[%s], R[%s] then t = R[%s] + R[%s], R[%s] = t, R[%s] = t and goto %s else goto %s"
        local name = OP_CODE[(code & 0x7F) + 1]
        local A = Bytedump:A(code)
        local Bx = Bytedump:Bx(code)
        print(index, name, string.format(f, A, A + 1, A + 2, A, A + 2, A, A + 3, index - Bx + 1, index + 1))
    end,
    OP_FORPREP = function(index, code)
        local f = "for i = R[%s], R[%s], R[%s] then R[%s] = R[%s] if R[%s] <= R[%s] goto %s else goto %s"
        local name = OP_CODE[(code & 0x7F) + 1]
        local A = Bytedump:A(code)
        local Bx = Bytedump:Bx(code)
        print(index, name, string.format(f, A, A + 1, A + 2, A + 3, A, A, A + 1, index + 1, index + Bx + 2))
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
        print(index, name, string.format(f, B, A, C, A))
    end,
    OP_CLOSURE = function(index, code)
        local f = "R[%s] = closure(P[%s])"
        local name = OP_CODE[(code & 0x7F) + 1]
        local A = Bytedump:A(code)
        local Bx = Bytedump:Bx(code)
        print(index, name, string.format(f, A, Bx))
    end,
    OP_VARARG = nil,
    OP_VARARGPREP = function(index, code)
        local f = "A:%s"
        local name = OP_CODE[(code & 0x7F) + 1]
        local A = Bytedump:A(code)
        print(index, name, string.format(f, A))
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
