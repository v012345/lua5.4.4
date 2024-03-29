NO_JUMP = -1
---@enum UnOpr
UnOpr = {
    OPR_MINUS = 1,
    OPR_BNOT = 2,
    OPR_NOT = 3,
    OPR_LEN = 4,
    OPR_NOUNOPR = 5
}
---@enum BinOpr
BinOpr = {
    OPR_ADD = 0,
    OPR_SUB = 1,
    OPR_MUL = 2,
    OPR_MOD = 3,
    OPR_POW = 4,
    OPR_DIV = 5,
    OPR_IDIV = 6,
    OPR_BAND = 7,
    OPR_BOR = 8,
    OPR_BXOR = 9,
    OPR_SHL = 10,
    OPR_SHR = 11,
    OPR_CONCAT = 12,
    OPR_EQ = 13,
    OPR_LT = 14,
    OPR_LE = 15,
    OPR_NE = 16,
    OPR_GT = 17,
    OPR_GE = 18,
    OPR_AND = 19,
    OPR_OR = 20,
    OPR_NOBINOPR = 21,
}
