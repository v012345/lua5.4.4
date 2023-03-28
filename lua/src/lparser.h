/*
** $Id: lparser.h $
** Lua Parser
** See Copyright Notice in lua.h
*/

#ifndef lparser_h
#define lparser_h

#include "llimits.h"
#include "lobject.h"
#include "lzio.h"

/*
** Expression and variable descriptor.
** Code generation for variables and expressions can be delayed to allow
** optimizations; An 'expdesc' structure describes a potentially-delayed
** variable/expression. It has a description of its "main" value plus a
** list of conditional jumps that can also produce its value (generated
** by short-circuit operators 'and'/'or').
*/

/* kinds of variables/expressions */
typedef enum {
    VVOID, /* when 'expdesc' describes the last expression of a list, this kind means an empty list (so, no expression) */
    VNIL, /* constant nil */
    VTRUE, /* constant true */
    VFALSE, /* constant false */
    VK, /* constant in 'k'; info = index of constant in 'k' */
    VKFLT, /* floating constant; nval = numerical float value */
    VKINT, /* integer constant; ival = numerical integer value */
    VKSTR, /* string constant; strval = TString address; (string is fixed by the lexer) */
    VNONRELOC, /* expression has its value in a fixed register; info = result register */
    VLOCAL, /* local variable; var.ridx = register index; var.vidx = relative index in 'actvar.arr'  */
    VUPVAL, /* upvalue variable; info = index of upvalue in 'upvalues' */
    VCONST, /* compile-time <const> variable; info = absolute index in 'actvar.arr'  */
    VINDEXED, /* indexed variable; ind.t = table register; ind.idx = key's R index */
    VINDEXUP, /* indexed upvalue; ind.t = table upvalue; ind.idx = key's K index */
    VINDEXI, /* indexed variable with constant integer; ind.t = table register; ind.idx = key's value */
    VINDEXSTR, /* indexed variable with literal string; ind.t = table register; ind.idx = key's K index */
    VJMP, /* expression is a test/comparison; info = pc of corresponding jump instruction */
    VRELOC, /* expression can put result in any register; info = instruction pc */
    VCALL, /* expression is a function call; info = instruction pc */
    VVARARG /* vararg expression; info = instruction pc */
} expkind;

#define vkisvar(k) (VLOCAL <= (k) && (k) <= VINDEXSTR)
#define vkisindexed(k) (VINDEXED <= (k) && (k) <= VINDEXSTR)

typedef struct expdesc {
    expkind k; // 当前表达式的类型
    union {
        lua_Integer ival; /* for VKINT */
        lua_Number nval; /* for VKFLT */
        TString* strval; /* for VKSTR */
        int info; /* for generic use */
        struct { /* for indexed variables */
            short idx; /* index (R or "long" K) */
            lu_byte t; /* table (register or upvalue) */
        } ind;
        struct { /* for local variables */
            lu_byte ridx; /* register holding the variable */
            unsigned short vidx; /* compiler index (in 'actvar.arr')  */
        } var;
    } u;
    int t; /* patch list of 'exit when true' */
    int f; /* patch list of 'exit when false' */
} expdesc;

/* kinds of variables */
#define VDKREG 0 /* 普通变量 regular */
#define RDKCONST 1 /* constant */
#define RDKTOCLOSE 2 /* to-be-closed */
#define RDKCTC 3 /* compile-time constant */

/* description of an active local variable */
typedef union Vardesc {
    struct {
        TValuefields; /* constant value (if it is a compile-time constant) */
        lu_byte kind;
        lu_byte ridx; /* register holding the variable */
        short pidx; /* index of the variable in the Proto's 'locvars' array */
        TString* name; /* variable name */
    } vd;
    TValue k; /* constant value (if any) */
} Vardesc;

/* description of pending goto statements and label statements */
typedef struct Labeldesc {
    TString* name; /* label identifier */
    int pc; /* position in code */
    int line; /* line where it appeared */
    lu_byte nactvar; /* number of active variables in that position */
    lu_byte close; /* goto that escapes upvalues */
} Labeldesc;

/* list of labels or gotos */
typedef struct Labellist {
    Labeldesc* arr; /* array */
    int n; /* number of entries in use */
    int size; /* array size */
} Labellist;

/* dynamic structures used by the parser */
typedef struct Dyndata {
    struct { /* list of all active local variables */
        Vardesc* arr; // 解析到的变量描述结构体的数组首地址
        int n; // arr数组已使用的数量
        int size; // arr数组申请到的数量
    } actvar;
    Labellist gt; /* list of pending gotos */
    Labellist label; /* list of active labels */
} Dyndata;

/* control of blocks */
struct BlockCnt; /* defined in lparser.c */

/* state needed to generate code for a given function */
typedef struct FuncState {
    Proto* f; /* 主要存放虚拟机指令，常量表等 current function header */
    struct FuncState* prev; /* enclosing function */
    struct LexState* ls; /* lexical state */
    struct BlockCnt* bl; /* chain of current blocks */
    int pc; /* 下一个指令，应当存放在Proto结构中的code列表的位置 next position to code (equivalent to 'ncode') */
    int lasttarget; /* 'label' of last 'jump label' */
    int previousline; /* last line that was saved in 'lineinfo' */
    int nk; /* 当前常量的数量 number of elements in 'k' */
    int np; /* 被编译的代码，Proto的数量 number of elements in 'p' */
    int nabslineinfo; /* number of elements in 'abslineinfo' */
    int firstlocal; /* 本 FuncState 的第一个 local 在 Dyndata数组中的索引; index of first local var (in Dyndata array) */
    int firstlabel; /* index of first label (in 'dyd->label->arr') */
    short ndebugvars; /* number of elements in 'f->locvars' */
    lu_byte nactvar; /* 当前函数解析出的 local 变量的数量; number of active local variables */
    lu_byte nups; /* 当前upvalue的数量 number of upvalues */
    lu_byte freereg; /* 下一个可被使用的，空闲寄存器的位置 first free register */
    lu_byte iwthabs; /* instructions issued since last absolute line info */
    lu_byte needclose; /* function needs to close upvalues when returning */
} FuncState;

LUAI_FUNC int luaY_nvarstack(FuncState* fs);
LUAI_FUNC LClosure* luaY_parser(lua_State* L, ZIO* z, Mbuffer* buff, Dyndata* dyd, const char* name, int firstchar);

#endif
