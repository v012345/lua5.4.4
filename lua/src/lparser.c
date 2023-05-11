/*
** $Id: lparser.c $
** Lua Parser
** See Copyright Notice in lua.h
*/

#define lparser_c
#define LUA_CORE

#include "lprefix.h"

#include <limits.h>
#include <string.h>

#include "lua.h"

#include "lcode.h"
#include "ldebug.h"
#include "ldo.h"
#include "lfunc.h"
#include "llex.h"
#include "lmem.h"
#include "lobject.h"
#include "lopcodes.h"
#include "lparser.h"
#include "lstate.h"
#include "lstring.h"
#include "ltable.h"

// maximum number of local variables per function (must be smaller than 250, due to the bytecode format)
#define MAXVARS 200

#define hasmultret(k) ((k) == VCALL || (k) == VVARARG)

// because all strings are unified by the scanner, the parser can use pointer equality for string equality
#define eqstr(a, b) ((a) == (b))

/*
** nodes for block list (list of active blocks)
*/
typedef struct BlockCnt {
    struct BlockCnt* previous; /* chain */
    int firstlabel; /* index of first label in this block */
    int firstgoto; /* index of first pending goto in this block */
    lu_byte nactvar; /* # active locals outside the block */
    lu_byte upval; /* true if some variable in the block is an upvalue */
    lu_byte isloop; /* true if 'block' is a loop */
    lu_byte insidetbc; /* true if inside the scope of a to-be-closed var. */
} BlockCnt;

/*
** prototypes for recursive non-terminal functions
*/
static void statement(LexState* ls);
static void expr(LexState* ls, expdesc* v);

static l_noret error_expected(LexState* ls, int token) { //
    luaX_syntaxerror(ls, luaO_pushfstring(ls->L, "%s expected", luaX_token2str(ls, token)));
}

static l_noret errorlimit(FuncState* fs, int limit, const char* what) {
    lua_State* L = fs->ls->L;
    const char* msg;
    int line = fs->f->linedefined;
    const char* where = (line == 0) ? "main function" : luaO_pushfstring(L, "function at line %d", line);
    msg = luaO_pushfstring(L, "too many %s (limit is %d) in %s", what, limit, where);
    luaX_syntaxerror(fs->ls, msg);
}

/// @brief v <= l, 否则报错
static void checklimit(FuncState* fs, int v, int l, const char* what) {
    if (v > l) errorlimit(fs, l, what);
}

/// @brief 看看一下 token 是不是 c, 如果是, 就跳过这个 token \r
/// Test whether next token is 'c'; if so, skip it.
static int testnext(LexState* ls, int c) {
    if (ls->t.token == c) {
        luaX_next(ls);
        return 1;
    } else
        return 0;
}

/// @brief Check that next token is 'c'.
static void check(LexState* ls, int c) {
    if (ls->t.token != c) //
        error_expected(ls, c);
}

/// @brief Check that next token is 'c' and skip it.
static void checknext(LexState* ls, int c) {
    check(ls, c);
    luaX_next(ls);
}

#define check_condition(ls, c, msg)                                                                                                                                                                    \
    {                                                                                                                                                                                                  \
        if (!(c)) luaX_syntaxerror(ls, msg);                                                                                                                                                           \
    }

/// @brief 看下一个 token 是不是 what, 如果是, 就跳过这个 token, 不是就报错 \r
/// Check that next token is 'what' and skip it. In case of error,
/// raise an error that the expected 'what' should match a 'who'
/// in line 'where' (if that is not the current line).
static void check_match(LexState* ls, int what, int who, int where) {
    if (l_unlikely(!testnext(ls, what))) {
        if (where == ls->linenumber) /* all in the same line? */
            error_expected(ls, what); /* do not need a complex message */
        else { luaX_syntaxerror(ls, luaO_pushfstring(ls->L, "%s expected (to close %s at line %d)", luaX_token2str(ls, what), luaX_token2str(ls, who), where)); }
    }
}

/// @brief 检查当前 token 是不是 TK_NAME,是,取下一个 token, 返回 TK_NAME 的变量名, 否则报错
static TString* str_checkname(LexState* ls) {
    TString* ts;
    check(ls, TK_NAME);
    ts = ls->t.seminfo.ts;
    luaX_next(ls);
    return ts;
}

/// @brief 初始化一个表达式描述结构
/// @param i 额外信息
/// VVARARG => i 存 OP_VARARG 指令
/// VUPVAL => i upvalues 中的索引值
/// VFALSE | VTRUE | VNIL | VKFLT | VKINT | VKSTR => 不使用 i
/// VVARARG => u.info 记录一条指令
static void init_exp(expdesc* e, expkind k, int i) {
    e->f = e->t = NO_JUMP;
    e->k = k;
    e->u.info = i;
}

/// @brief 初始化一个字符串常量 expdesc; 类型为 VKSTR , strval 为 TString 的地址
static void codestring(expdesc* e, TString* s) {
    e->f = e->t = NO_JUMP;
    e->k = VKSTR;
    e->u.strval = s;
}

/// @brief e->k = VKSTR; e->u.strval = str_checkname(ls);
static void codename(LexState* ls, expdesc* e) { //
    codestring(e, str_checkname(ls));
}

/// @brief 局部变量的寄存器分配完毕后, 这里记录变量的名字与对应的指令, 返回变量在 locvars 中的索引 \r
/// Register a new local variable in the active 'Proto' (for debug information).
static int registerlocalvar(LexState* ls, FuncState* fs, TString* varname) {
    Proto* f = fs->f;
    int oldsize = f->sizelocvars;
    luaM_growvector(ls->L, f->locvars, fs->ndebugvars, f->sizelocvars, LocVar, SHRT_MAX, "local variables");
    while (oldsize < f->sizelocvars) //
        f->locvars[oldsize++].varname = NULL;
    f->locvars[fs->ndebugvars].varname = varname;
    f->locvars[fs->ndebugvars].startpc = fs->pc; // 当前变量对应的指令
    luaC_objbarrier(ls->L, f, varname);
    return fs->ndebugvars++;
}

/// @brief 通过名字记录一个局部变量, 注意, 这里只是把变量记录到 actvar.aar 中, fs 的 nactvar 还没有更新, 也没有分配寄存器 \r
/// Create a new local variable with the given 'name'. Return its index in the function.
static int new_localvar(LexState* ls, TString* name) {
    lua_State* L = ls->L;
    FuncState* fs = ls->fs;
    Dyndata* dyd = ls->dyd;
    Vardesc* var;
    checklimit(fs, dyd->actvar.n + 1 - fs->firstlocal, MAXVARS, "local variables");
    luaM_growvector(L, dyd->actvar.arr, dyd->actvar.n + 1, dyd->actvar.size, Vardesc, USHRT_MAX, "local variables");
    var = &dyd->actvar.arr[dyd->actvar.n++];
    var->vd.kind = VDKREG; /* default */
    var->vd.name = name;
    return dyd->actvar.n - 1 - fs->firstlocal;
}

// 通过名字记录一个局部变量
#define new_localvarliteral(ls, v) new_localvar(ls, luaX_newstring(ls, "" v, (sizeof(v) / sizeof(char)) - 1));

/// @brief 通过索引拿到局部变量的描述结构 \r
/// Return the "variable description" (Vardesc) of a given variable.
/// (Unless noted otherwise, all variables are referred to by their compiler indices.)
static Vardesc* getlocalvardesc(FuncState* fs, int vidx) { //
    return &fs->ls->dyd->actvar.arr[fs->firstlocal + vidx];
}

/// @brief 从 nvar 反向查找, 返回一个可用的寄存器索引 \r
/// Convert 'nvar', a compiler index level, to its corresponding
/// register. For that, search for the highest variable below that level
/// that is in a register and uses its register index ('ridx') plus one.
static int reglevel(FuncState* fs, int nvar) {
    while (nvar-- > 0) {
        Vardesc* vd = getlocalvardesc(fs, nvar); /* get previous variable */
        if (vd->vd.kind != RDKCTC) /* is in a register? */
            return vd->vd.ridx + 1;
    }
    return 0; /* no variables in registers */
}

/// @brief 当前函数有效的局部变量数(重复声明同名的局部变量, 会使用之前的变量失效) \r
/// Return the number of variables in the register stack for the given function.
int luaY_nvarstack(FuncState* fs) { //
    // nactvar 为已经确认为有效局部变量的个数
    return reglevel(fs, fs->nactvar);
}

/*
** Get the debug-information entry for current variable 'vidx'.
*/
static LocVar* localdebuginfo(FuncState* fs, int vidx) {
    Vardesc* vd = getlocalvardesc(fs, vidx);
    if (vd->vd.kind == RDKCTC)
        return NULL; /* no debug info. for constants */
    else {
        int idx = vd->vd.pidx;
        lua_assert(idx < fs->ndebugvars);
        return &fs->f->locvars[idx];
    }
}

/// @brief 使用一个 VLOCAL 表达式 vidx 为变量的索引, ridx 为寄存器索引 \r
/// Create an expression representing variable 'vidx'
static void init_var(FuncState* fs, expdesc* e, int vidx) {
    e->f = e->t = NO_JUMP;
    e->k = VLOCAL; // 已经解析完毕, 且分配了寄存器
    e->u.var.vidx = vidx; // actvar.arr 索引
    e->u.var.ridx = getlocalvardesc(fs, vidx)->vd.ridx; // 寄存器索引
}

/*
** Raises an error if variable described by 'e' is read only
*/
static void check_readonly(LexState* ls, expdesc* e) {
    FuncState* fs = ls->fs;
    TString* varname = NULL; /* to be set if variable is const */
    switch (e->k) {
        case VCONST: {
            varname = ls->dyd->actvar.arr[e->u.info].vd.name;
            break;
        }
        case VLOCAL: {
            Vardesc* vardesc = getlocalvardesc(fs, e->u.var.vidx);
            if (vardesc->vd.kind != VDKREG) /* not a regular variable? */
                varname = vardesc->vd.name;
            break;
        }
        case VUPVAL: {
            Upvaldesc* up = &fs->f->upvalues[e->u.info];
            if (up->kind != VDKREG) varname = up->name;
            break;
        }
        default: return; /* other cases cannot be read-only */
    }
    if (varname) {
        const char* msg = luaO_pushfstring(ls->L, "attempt to assign to const variable '%s'", getstr(varname));
        luaK_semerror(ls, msg); /* error */
    }
}

/// @brief 变量已经存到了 arr 中, 这里为新增加变量分配寄存器, 同时增加 nactvar \r
/// Start the scope for the last 'nvars' created variables.
static void adjustlocalvars(LexState* ls, int nvars) {
    FuncState* fs = ls->fs;
    // 找到一个可用的寄存器
    int reglevel = luaY_nvarstack(fs);
    int i;
    for (i = 0; i < nvars; i++) {
        int vidx = fs->nactvar++; // 与寄存器同步增加
        Vardesc* var = getlocalvardesc(fs, vidx); // 之前已经放到数组里了
        var->vd.ridx = reglevel++; // 指出变量使用的寄存器
        var->vd.pidx = registerlocalvar(ls, fs, var->vd.name);
    }
}

/// @brief 从尾部移除 actvar.arr 中活动变量 \r
/// Close the scope for all variables up to level 'tolevel'. (debug info.)
/// @param tolevel 要移除的变量的数量
static void removevars(FuncState* fs, int tolevel) {
    fs->ls->dyd->actvar.n -= (fs->nactvar - tolevel);
    while (fs->nactvar > tolevel) {
        LocVar* var = localdebuginfo(fs, --fs->nactvar);
        if (var) /* does it have debug information? */
            var->endpc = fs->pc;
    }
}

/// @brief 在函数的 Upvalues 中找
/// Search the upvalues of the function 'fs' for one with the given 'name'.
/// @param name 变量名
/// @return 找到返回索引, 否则返回 -1
static int searchupvalue(FuncState* fs, TString* name) {
    int i;
    Upvaldesc* up = fs->f->upvalues;
    for (i = 0; i < fs->nups; i++) {
        if (eqstr(up[i].name, name)) //
            return i;
    }
    return -1; /* not found */
}

/// @brief 分配出一个可用的 Upvaldesc, 同时记录分配的个数 nups
/// @return 返回一个可用的 Upvaldesc
static Upvaldesc* allocupvalue(FuncState* fs) {
    Proto* f = fs->f;
    int oldsize = f->sizeupvalues;
    checklimit(fs, fs->nups + 1, MAXUPVAL, "upvalues");
    luaM_growvector(fs->ls->L, f->upvalues, fs->nups, f->sizeupvalues, Upvaldesc, MAXUPVAL, "upvalues");
    // 上一步分配完内存后, f->sizeupvalues 至少为 4
    while (oldsize < f->sizeupvalues) //
        f->upvalues[oldsize++].name = NULL;
    return &f->upvalues[fs->nups++];
}

/// @brief 当解析出来的表达式类型是 local 或 upvalue 时, 要为当时函数生成新的 Upvaldesc
/// @return 返回此 upvalue 的索引
static int newupvalue(FuncState* fs, TString* name, expdesc* v) {
    Upvaldesc* up = allocupvalue(fs);
    FuncState* prev = fs->prev; // 必定是在上一级函数中找到的
    if (v->k == VLOCAL) {
        up->instack = 1; // 变量是上一级函数的局部变量, 所以在栈里
        up->idx = v->u.var.ridx; // 在寄存器(数据栈)的位置, 相对于变量所在函数
        up->kind = getlocalvardesc(prev, v->u.var.vidx)->vd.kind;
        lua_assert(eqstr(name, getlocalvardesc(prev, v->u.var.vidx)->vd.name));
    } else {
        up->instack = 0; // 来自上层函数的 upvalue 就不在栈里
        up->idx = cast_byte(v->u.info); // 在上层函数 Upvaldesc 数组中的位置
        up->kind = prev->f->upvalues[v->u.info].kind; // 与上层函数 Upvaldesc 的 kind 一至
        lua_assert(eqstr(name, prev->f->upvalues[v->u.info].name));
    }
    up->name = name;
    luaC_objbarrier(fs->ls->L, fs->f, name);
    return fs->nups - 1;
}

/// @brief 反向遍历 fs 已解析出来的局部变量, 通过变量名来找对应变量 \r
/// Look for an active local variable with the name 'n' in the function 'fs'.
/// If found, initialize 'var' with it and return its expression kind; otherwise return -1.
/// @return 如果找到就返回变量类型(VCONST 与 VLOCAL), 并且填充 var, 否则返回 -1
static int searchvar(FuncState* fs, TString* n, expdesc* var) {
    int i;
    for (i = cast_int(fs->nactvar) - 1; i >= 0; i--) {
        Vardesc* vd = getlocalvardesc(fs, i);
        if (eqstr(n, vd->vd.name)) { /* found? */
            if (vd->vd.kind == RDKCTC) /* compile-time constant? */
                init_exp(var, VCONST, fs->firstlocal + i);
            else /* real variable */
                init_var(fs, var, i);
            return var->k;
        }
    }
    return -1; /* not found */
}

/// @brief 找到局部变量所在的作用域, 标记一下引作用域, 之后关闭 upvalues 要用到
/// Mark block where variable at given level was defined (to emit close instructions later).
/// @param level 为当前函数的局部变量基于当前函数在 actvar.arr 中的索引
static void markupval(FuncState* fs, int level) {
    BlockCnt* bl = fs->bl; // 取当前代码块, bl 都是基于 fs 的
    // 此处 nactvar 为引 block 外部的有效变量数量
    while (bl->nactvar > level) //
        bl = bl->previous;
    bl->upval = 1; // 表示此代码块的子块有使用引块的局部变量
    fs->needclose = 1;
}

/*
** Mark that current block has a to-be-closed variable.
*/
static void marktobeclosed(FuncState* fs) {
    BlockCnt* bl = fs->bl;
    bl->upval = 1;
    bl->insidetbc = 1;
    fs->needclose = 1;
}

/// @brief singlevar 的辅助函数, 先在当前函数里查, 再递归到父级里查, 通过 var 传递信息 \r
/// Find a variable with the given name 'n'. If it is an upvalue, add this upvalue
/// into all intermediate functions. If it is a global, set 'var' as 'void' as a flag.
/// @param n 变量的名称
/// @param var 要被填充的 expdesc
/// @param base 1 为当前作用域, 0 为父级作用域
static void singlevaraux(FuncState* fs, TString* n, expdesc* var, int base) {
    if (fs == NULL) /* no more levels? */
        init_exp(var, VVOID, 0); /* default is global */
    else {
        int v = searchvar(fs, n, var); /* look up locals at current level */
        if (v >= 0) { /* found? */
            if (v == VLOCAL && !base) /* local will be used as an upval */
                markupval(fs, var->u.var.vidx);
        } else { /* not found as local at current level; try upvalues */
            int idx = searchupvalue(fs, n); /* try existing upvalues */
            if (idx < 0) { /* not found? */
                singlevaraux(fs->prev, n, var, 0); /* try upper levels */
                // 如果在某一级找到了, 更新中间函数的 upvalues
                if (var->k == VLOCAL || var->k == VUPVAL) /* local or upvalue? */
                    idx = newupvalue(fs, n, var); /* will be a new upvalue */
                // 这里就是找到头了 var->k = VVOID 了
                else /* it is a global or a constant */
                    return; /* don't need to do anything at this level */
            }
            init_exp(var, VUPVAL, idx); /* new or old upvalue */
        }
    }
}

/// @brief 通过解析到的变量名来找变量, 如果没找到, 变当作全局变量 \r
/// Find a variable with the given name 'n', handling global variables too.
static void singlevar(LexState* ls, expdesc* var) {
    TString* varname = str_checkname(ls);
    FuncState* fs = ls->fs;
    singlevaraux(fs, varname, var, 1);
    if (var->k == VVOID) { /* global name? */
        expdesc key;
        singlevaraux(fs, ls->envn, var, 1); /* get environment variable */
        // var 现在表示 _ENV 这个 upvalue
        lua_assert(var->k != VVOID); /* this one must exist */
        codestring(&key, varname); /* key is variable name */
        // key 现在记录着变量名
        luaK_indexed(fs, var, &key); /* env[varname] */
    }
}

/// @brief Adjust the number of results from an expression list 'e' with 'nexps' expressions to 'nvars' values.
static void adjust_assign(LexState* ls, int nvars, int nexps, expdesc* e) {
    FuncState* fs = ls->fs;
    int needed = nvars - nexps; /* extra values needed */
    if (hasmultret(e->k)) { /* last expression has multiple returns? */
        int extra = needed + 1; /* discount last expression itself */
        if (extra < 0) extra = 0;
        luaK_setreturns(fs, e, extra); /* last exp. provides the difference */
    } else {
        if (e->k != VVOID) /* at least one expression? */
            luaK_exp2nextreg(fs, e); /* close last expression */
        if (needed > 0) /* missing values? */
            luaK_nil(fs, fs->freereg, needed); /* complete with nils */
    }
    if (needed > 0)
        luaK_reserveregs(fs, needed); /* registers for extra values */
    else /* adding 'needed' is actually a subtraction */
        fs->freereg += needed; /* remove extra values */
}

#define enterlevel(ls) luaE_incCstack(ls->L)

#define leavelevel(ls) ((ls)->L->nCcalls--)

/*
** Generates an error that a goto jumps into the scope of some
** local variable.
*/
static l_noret jumpscopeerror(LexState* ls, Labeldesc* gt) {
    const char* varname = getstr(getlocalvardesc(ls->fs, gt->nactvar)->vd.name);
    const char* msg = "<goto %s> at line %d jumps into the scope of local '%s'";
    msg = luaO_pushfstring(ls->L, msg, getstr(gt->name), gt->line, varname);
    luaK_semerror(ls, msg); /* raise the error */
}

/*
** Solves the goto at index 'g' to given 'label' and removes it
** from the list of pending goto's.
** If it jumps into the scope of some variable, raises an error.
*/
static void solvegoto(LexState* ls, int g, Labeldesc* label) {
    int i;
    Labellist* gl = &ls->dyd->gt; /* list of goto's */
    Labeldesc* gt = &gl->arr[g]; /* goto to be resolved */
    lua_assert(eqstr(gt->name, label->name));
    if (l_unlikely(gt->nactvar < label->nactvar)) /* enter some scope? */
        jumpscopeerror(ls, gt);
    luaK_patchlist(ls->fs, gt->pc, label->pc);
    for (i = g; i < gl->n - 1; i++) /* remove goto from pending list */
        gl->arr[i] = gl->arr[i + 1];
    gl->n--;
}

/// @brief Search for an active label with the given name.
static Labeldesc* findlabel(LexState* ls, TString* name) {
    int i;
    Dyndata* dyd = ls->dyd;
    /* check labels in current function for a match */
    for (i = ls->fs->firstlabel; i < dyd->label.n; i++) {
        Labeldesc* lb = &dyd->label.arr[i];
        if (eqstr(lb->name, name)) /* correct label? */
            return lb;
    }
    return NULL; /* label not found */
}

/// @brief Adds a new label/goto in the corresponding list.
/// @param name label identifier
/// @param line line where it appeared
/// @param pc position in code
/// @return number of entries in use
static int newlabelentry(LexState* ls, Labellist* l, TString* name, int line, int pc) {
    int n = l->n;
    luaM_growvector(ls->L, l->arr, n, l->size, Labeldesc, SHRT_MAX, "labels/gotos");
    l->arr[n].name = name;
    l->arr[n].line = line;
    l->arr[n].nactvar = ls->fs->nactvar;
    l->arr[n].close = 0;
    l->arr[n].pc = pc;
    l->n = n + 1;
    return n;
}

static int newgotoentry(LexState* ls, TString* name, int line, int pc) { //
    return newlabelentry(ls, &ls->dyd->gt, name, line, pc);
}

/*
** Solves forward jumps. Check whether new label 'lb' matches any
** pending gotos in current block and solves them. Return true
** if any of the goto's need to close upvalues.
*/
static int solvegotos(LexState* ls, Labeldesc* lb) {
    Labellist* gl = &ls->dyd->gt;
    int i = ls->fs->bl->firstgoto;
    int needsclose = 0;
    while (i < gl->n) {
        if (eqstr(gl->arr[i].name, lb->name)) {
            needsclose |= gl->arr[i].close;
            solvegoto(ls, i, lb); /* will remove 'i' from the list */
        } else
            i++;
    }
    return needsclose;
}

/*
** Create a new label with the given 'name' at the given 'line'.
** 'last' tells whether label is the last non-op statement in its
** block. Solves all pending goto's to this new label and adds
** a close instruction if necessary.
** Returns true iff it added a close instruction.
*/
static int createlabel(LexState* ls, TString* name, int line, int last) {
    FuncState* fs = ls->fs;
    Labellist* ll = &ls->dyd->label;
    int l = newlabelentry(ls, ll, name, line, luaK_getlabel(fs));
    if (last) { /* label is last no-op statement in the block? */
        /* assume that locals are already out of scope */
        ll->arr[l].nactvar = fs->bl->nactvar;
    }
    if (solvegotos(ls, &ll->arr[l])) { /* need close? */
        luaK_codeABC(fs, OP_CLOSE, luaY_nvarstack(fs), 0, 0);
        return 1;
    }
    return 0;
}

/*
** Adjust pending gotos to outer level of a block.
*/
static void movegotosout(FuncState* fs, BlockCnt* bl) {
    int i;
    Labellist* gl = &fs->ls->dyd->gt;
    /* correct pending gotos to current block */
    for (i = bl->firstgoto; i < gl->n; i++) { /* for each pending goto */
        Labeldesc* gt = &gl->arr[i];
        /* leaving a variable scope? */
        if (reglevel(fs, gt->nactvar) > reglevel(fs, bl->nactvar)) //
            gt->close |= bl->upval; /* jump may need a close */
        gt->nactvar = bl->nactvar; /* update goto level */
    }
}

/// @brief 进入一个 block
/// @param bl 指向要进入的 block
/// @param isloop 1 为循环体, 0 为非循环体
static void enterblock(FuncState* fs, BlockCnt* bl, lu_byte isloop) {
    bl->isloop = isloop;
    // 如果是新函数, nactvar 为 0, 如果是代码块, 那就是当前函数解析出的有效局部变量
    bl->nactvar = fs->nactvar; // 一进入就确定了, 之后不会变了
    bl->firstlabel = fs->ls->dyd->label.n;
    bl->firstgoto = fs->ls->dyd->gt.n; // 一进入就确定了, 之后不会变了
    bl->upval = 0; // 此 block 是否有 upvalues
    bl->insidetbc = (fs->bl != NULL && fs->bl->insidetbc);
    bl->previous = fs->bl; // 把 block 接到链上
    fs->bl = bl; // 更新函数状态机上的块状态机
    // 进入新 block 时, 所有表达式都已算完, 此时不需要临时寄存器了
    lua_assert(fs->freereg == luaY_nvarstack(fs));
}

/// @brief generates an error for an undefined 'goto'.
static l_noret undefgoto(LexState* ls, Labeldesc* gt) {
    const char* msg;
    if (eqstr(gt->name, luaS_newliteral(ls->L, "break"))) {
        msg = "break outside loop at line %d";
        msg = luaO_pushfstring(ls->L, msg, gt->line);
    } else {
        msg = "no visible label '%s' for <goto> at line %d";
        msg = luaO_pushfstring(ls->L, msg, getstr(gt->name), gt->line);
    }
    luaK_semerror(ls, msg);
}

static void leaveblock(FuncState* fs) {
    BlockCnt* bl = fs->bl; // 拿到当前的 block
    LexState* ls = fs->ls;
    int hasclose = 0;
    int stklevel = reglevel(fs, bl->nactvar); /* level outside the block */
    if (bl->isloop) /* fix pending breaks? */
        hasclose = createlabel(ls, luaS_newliteral(ls->L, "break"), 0, 0);
    if (!hasclose && bl->previous && bl->upval) //
        luaK_codeABC(fs, OP_CLOSE, stklevel, 0, 0);
    fs->bl = bl->previous; // 去年 block 链层的元素
    removevars(fs, bl->nactvar);
    lua_assert(bl->nactvar == fs->nactvar);
    fs->freereg = stklevel; /* free registers */
    ls->dyd->label.n = bl->firstlabel; /* remove local labels */
    if (bl->previous) /* inner block? */
        movegotosout(fs, bl); /* update pending gotos to outer block */
    else {
        if (bl->firstgoto < ls->dyd->gt.n) /* pending gotos in outer block? */
            undefgoto(ls, &ls->dyd->gt.arr[bl->firstgoto]); /* error */
    }
}

/// @brief 函数原型链上加上一个函数原型, 返回此原型
/// adds a new prototype into list of prototypes
static Proto* addprototype(LexState* ls) {
    Proto* clp;
    lua_State* L = ls->L;
    FuncState* fs = ls->fs;
    Proto* f = fs->f; /* prototype of current function */
    if (fs->np >= f->sizep) {
        int oldsize = f->sizep;
        luaM_growvector(L, f->p, fs->np, f->sizep, Proto*, MAXARG_Bx, "functions");
        while (oldsize < f->sizep) f->p[oldsize++] = NULL;
    }
    f->p[fs->np++] = clp = luaF_newproto(L);
    luaC_objbarrier(L, f, clp);
    return clp;
}

/*
** codes instruction to create new closure in parent function.
** The OP_CLOSURE instruction uses the last available register,
** so that, if it invokes the GC, the GC knows which registers
** are in use at that time.

*/
static void codeclosure(LexState* ls, expdesc* v) {
    FuncState* fs = ls->fs->prev;
    init_exp(v, VRELOC, luaK_codeABx(fs, OP_CLOSURE, 0, fs->np - 1));
    luaK_exp2nextreg(fs, v); /* fix it at the last register */
}

static void open_func(LexState* ls, FuncState* fs, BlockCnt* bl) {
    Proto* f = fs->f;
    fs->prev = ls->fs; /* linked list of funcstates */
    fs->ls = ls;
    ls->fs = fs; // 理新词法状态机上的函数状态机
    fs->pc = 0;
    fs->previousline = f->linedefined;
    fs->iwthabs = 0;
    fs->lasttarget = 0;
    fs->freereg = 0;
    fs->nk = 0;
    fs->nabslineinfo = 0;
    fs->np = 0;
    fs->nups = 0;
    fs->ndebugvars = 0;
    fs->nactvar = 0;
    fs->needclose = 0;
    fs->firstlocal = ls->dyd->actvar.n; // 当前函数的第一个局部变量在 actvar.aar 中的位置
    fs->firstlabel = ls->dyd->label.n;
    fs->bl = NULL; // 函数状态机初始化时, block 是 NULL
    f->source = ls->source;
    luaC_objbarrier(ls->L, f, f->source);
    f->maxstacksize = 2; /* registers 0/1 are always valid */
    // 上面都是在初始化 FuncState, 下面才记录代码块状态
    enterblock(fs, bl, 0);
}

static void close_func(LexState* ls) {
    lua_State* L = ls->L;
    FuncState* fs = ls->fs;
    Proto* f = fs->f;
    // 不管如何函数有没有 return, 都会在编译关闭函数时, 插入一个 没有返回值的 return
    luaK_ret(fs, luaY_nvarstack(fs), 0); /* final return */
    leaveblock(fs);
    lua_assert(fs->bl == NULL);
    luaK_finish(fs);
    luaM_shrinkvector(L, f->code, f->sizecode, fs->pc, Instruction);
    luaM_shrinkvector(L, f->lineinfo, f->sizelineinfo, fs->pc, ls_byte);
    luaM_shrinkvector(L, f->abslineinfo, f->sizeabslineinfo, fs->nabslineinfo, AbsLineInfo);
    luaM_shrinkvector(L, f->k, f->sizek, fs->nk, TValue);
    luaM_shrinkvector(L, f->p, f->sizep, fs->np, Proto*);
    luaM_shrinkvector(L, f->locvars, f->sizelocvars, fs->ndebugvars, LocVar);
    luaM_shrinkvector(L, f->upvalues, f->sizeupvalues, fs->nups, Upvaldesc);
    ls->fs = fs->prev;
    luaC_checkGC(L);
}

/*============================================================*/
/* GRAMMAR RULES */
/*============================================================*/

/*
** check whether current token is in the follow set of a block.
** 'until' closes syntactical blocks, but do not close scope,
** so it is handled in separate.
*/
static int block_follow(LexState* ls, int withuntil) {
    switch (ls->t.token) {
        case TK_ELSE: // else 有一点像 end
        case TK_ELSEIF: // elseif 也有一点像 end
        case TK_END: // 一个语句块结束了
        case TK_EOS: // 文件结束了
            return 1;
        case TK_UNTIL: // until 有一点特殊, 我目前还不知道
            return withuntil;
        default: return 0;
    }
}

/// @brief 解析语句组
static void statlist(LexState* ls) {
    /* statlist -> { stat [';'] } */
    while (!block_follow(ls, 1)) {
        if (ls->t.token == TK_RETURN) {
            statement(ls);
            return; /* 'return' must be last statement */
        }
        statement(ls);
    }
}

static void fieldsel(LexState* ls, expdesc* v) {
    /* fieldsel -> ['.' | ':'] NAME */
    FuncState* fs = ls->fs;
    expdesc key;
    luaK_exp2anyregup(fs, v);
    luaX_next(ls); /* skip the dot or colon */
    codename(ls, &key); // 解析字段名，并将其存储在 key 中
    luaK_indexed(fs, v, &key);
}

/// @brief 表的记录字段的键的解析
static void yindex(LexState* ls, expdesc* v) {
    /* index -> '[' expr ']' */
    luaX_next(ls); /* skip the '[' */
    expr(ls, v);
    luaK_exp2val(ls->fs, v);
    checknext(ls, ']');
}

/*
** {======================================================================
** Rules for Constructors
** =======================================================================
*/

typedef struct ConsControl {
    expdesc v; /* last list item read */
    expdesc* t; /* table descriptor */
    int nh; /* total number of 'record' elements */
    int na; /* number of array elements already stored */
    int tostore; /* number of array elements pending to be stored */
} ConsControl;

static void recfield(LexState* ls, ConsControl* cc) {
    /* recfield -> (NAME | '['exp']') = exp */
    FuncState* fs = ls->fs;
    int reg = ls->fs->freereg;
    expdesc //
        tab, // 表的描述结构
        key, // 键名描述结构
        val; // 值表达式的描述结构
    if (ls->t.token == TK_NAME) {
        checklimit(fs, cc->nh, MAX_INT, "items in a constructor");
        codename(ls, &key); // 设置键的名
    } else /* ls->t.token == '[' */
        yindex(ls, &key);
    cc->nh++; // record 的数量加 1
    checknext(ls, '=');
    tab = *cc->t;
    // 这里把键的信息存放到 tab 的 info 中, tab 为 VNONRELOC
    luaK_indexed(fs, &tab, &key);
    expr(ls, &val); // 值是一个表达式
    luaK_storevar(fs, &tab, &val);
    fs->freereg = reg; /* free registers */
}

static void closelistfield(FuncState* fs, ConsControl* cc) {
    if (cc->v.k == VVOID) //
        return; /* there is no list item */
    luaK_exp2nextreg(fs, &cc->v);
    cc->v.k = VVOID;
    if (cc->tostore == LFIELDS_PER_FLUSH) {
        luaK_setlist(fs, cc->t->u.info, cc->na, cc->tostore); /* flush */
        cc->na += cc->tostore;
        cc->tostore = 0; /* no more items pending */
    }
}

static void lastlistfield(FuncState* fs, ConsControl* cc) {
    if (cc->tostore == 0) return;
    if (hasmultret(cc->v.k)) {
        luaK_setmultret(fs, &cc->v);
        luaK_setlist(fs, cc->t->u.info, cc->na, LUA_MULTRET);
        cc->na--; /* do not count last expression (unknown number of elements) */
    } else {
        if (cc->v.k != VVOID) luaK_exp2nextreg(fs, &cc->v);
        luaK_setlist(fs, cc->t->u.info, cc->na, cc->tostore);
    }
    cc->na += cc->tostore;
}

static void listfield(LexState* ls, ConsControl* cc) {
    /* listfield -> exp */
    expr(ls, &cc->v);
    cc->tostore++;
}

static void field(LexState* ls, ConsControl* cc) {
    /* field -> listfield | recfield */
    switch (ls->t.token) {
        case TK_NAME: { /* may be 'listfield' or 'recfield' */
            if (luaX_lookahead(ls) != '=') /* expression? */
                listfield(ls, cc);
            else
                recfield(ls, cc);
            break;
        }
        case '[': {
            recfield(ls, cc);
            break;
        }
        default: {
            listfield(ls, cc);
            break;
        }
    }
}

static void constructor(LexState* ls, expdesc* t) {
    /* constructor -> '{' [ field { sep field } [sep] ] '}'
       sep -> ',' | ';' */
    FuncState* fs = ls->fs;
    int line = ls->linenumber;
    int pc = luaK_codeABC(fs, OP_NEWTABLE, 0, 0, 0);
    ConsControl cc; // 解析表时, 用来存储解析的状态
    luaK_code(fs, 0); /* space for extra arg. */
    cc.na = cc.nh = cc.tostore = 0;
    cc.t = t;
    // 表在哪里声明就放到哪里
    init_exp(t, VNONRELOC, fs->freereg); /* table will be at stack top */
    luaK_reserveregs(fs, 1);
    init_exp(&cc.v, VVOID, 0); /* no value (yet) */
    checknext(ls, '{');
    do {
        lua_assert(cc.v.k == VVOID || cc.tostore > 0);
        if (ls->t.token == '}') break;
        closelistfield(fs, &cc);
        field(ls, &cc);
    } while (testnext(ls, ',') || testnext(ls, ';'));
    check_match(ls, '}', '{', line);
    lastlistfield(fs, &cc);
    luaK_settablesize(fs, pc, t->u.info, cc.na, cc.nh);
}

/* }====================================================================== */

/// @brief 把当前函数设置成可接受可变长参数的函数
/// @param nparams 固定参数的数量
static void setvararg(FuncState* fs, int nparams) {
    fs->f->is_vararg = 1;
    luaK_codeABC(fs, OP_VARARGPREP, nparams, 0, 0);
}

static void parlist(LexState* ls) {
    /* parlist -> [ {NAME ','} (NAME | '...') ] */
    FuncState* fs = ls->fs;
    Proto* f = fs->f;
    int nparams = 0;
    int isvararg = 0;
    if (ls->t.token != ')') { /* is 'parlist' not empty? */
        do {
            switch (ls->t.token) {
                case TK_NAME: {
                    new_localvar(ls, str_checkname(ls));
                    nparams++;
                    break;
                }
                case TK_DOTS: {
                    luaX_next(ls);
                    isvararg = 1;
                    break;
                }
                default: luaX_syntaxerror(ls, "<name> or '...' expected");
            }
        } while (!isvararg && testnext(ls, ','));
    }
    adjustlocalvars(ls, nparams);
    // 上面只是刚刚分析完参数列表, 所以这里 nactvar 就是函数签名中参数的个数
    f->numparams = cast_byte(fs->nactvar); //
    if (isvararg) // 如果参数列表最后是 ... , 就是可变参数
        setvararg(fs, f->numparams); /* declared vararg */
    // 为参数预留寄存器
    luaK_reserveregs(fs, fs->nactvar); /* reserve registers for parameters */
}

static void body(LexState* ls, expdesc* e, int ismethod, int line) {
    /* body ->  '(' parlist ')' block END */
    FuncState new_fs; // 新函数来了
    BlockCnt bl;
    new_fs.f = addprototype(ls);
    new_fs.f->linedefined = line;
    open_func(ls, &new_fs, &bl); // 进入新的代码块
    checknext(ls, '(');
    if (ismethod) { // 如果是使用了 : , 在这里帮补上一个 self
        new_localvarliteral(ls, "self"); /* create 'self' parameter */
        adjustlocalvars(ls, 1);
    }
    parlist(ls);
    checknext(ls, ')');
    statlist(ls);
    new_fs.f->lastlinedefined = ls->linenumber;
    check_match(ls, TK_END, TK_FUNCTION, line);
    codeclosure(ls, e);
    close_func(ls);
}

/// @brief 返回解析到的表达式列表中表达式的个数, v 记录表达式列表的最后一个表达式
static int explist(LexState* ls, expdesc* v) {
    /* explist -> expr { ',' expr } */
    int n = 1; /* at least one expression */
    expr(ls, v);
    while (testnext(ls, ',')) {
        luaK_exp2nextreg(ls->fs, v);
        expr(ls, v);
        n++;
    }
    return n;
}

static void funcargs(LexState* ls, expdesc* f, int line) {
    FuncState* fs = ls->fs;
    expdesc args; // 函数的最后一个参数的描述结构
    int base, nparams;
    switch (ls->t.token) {
        case '(': { /* funcargs -> '(' [ explist ] ')' */
            luaX_next(ls);
            if (ls->t.token == ')') /* arg list is empty? */
                args.k = VVOID;
            else {
                explist(ls, &args); // 解析一下参数列表
                // 这里就是只有最后一参数是函数调用时, 才会使用全部返回值
                if (hasmultret(args.k)) // 最后一个参数是函数调用或显式多参
                    luaK_setmultret(fs, &args);
            }
            check_match(ls, ')', '(', line);
            break;
        }
        case '{': { /* funcargs -> constructor */ constructor(ls, &args); break;
        }
        case TK_STRING: { /* funcargs -> STRING */
            codestring(&args, ls->t.seminfo.ts);
            luaX_next(ls); /* must use 'seminfo' before 'next' */
            break;
        }
        default: {
            luaX_syntaxerror(ls, "function arguments expected");
        }
    }
    lua_assert(f->k == VNONRELOC);
    // 这里 info 是解析到的函数名所在的寄存器索引
    base = f->u.info; /* base register for call */
    if (hasmultret(args.k))
        nparams = LUA_MULTRET; /* open call */
    else {
        if (args.k != VVOID) // 有参数
            luaK_exp2nextreg(fs, &args); /* close last argument */
        nparams = fs->freereg - (base + 1); // 实际解析到的参数个数
    }
    // 更新 f 的类型为 VCALL, info 存储指令, base 为函数所在寄存器
    // 如果 nparams + 1 大于 0, 说明是固定参数, +1 是了之后直接以 base 为基础
    // 加上指令中的 B 值, 直接确定出 L->top 的位置
    init_exp(f, VCALL, luaK_codeABC(fs, OP_CALL, base, nparams + 1, 2));
    luaK_fixline(fs, line);
    /* call remove function and arguments and leaves (unless changed) one result */
    fs->freereg = base + 1;
}

/*
** {======================================================================
** Expression parsing
** =======================================================================
*/

/// @brief 基本表达式, 缀表达式的核心部分
static void primaryexp(LexState* ls, expdesc* v) {
    /* primaryexp -> NAME | '(' expr ')' */
    switch (ls->t.token) {
        case '(': {
            int line = ls->linenumber;
            luaX_next(ls);
            expr(ls, v);
            check_match(ls, ')', '(', line);
            luaK_dischargevars(ls->fs, v);
            return;
        }
        case TK_NAME: {
            singlevar(ls, v);
            return;
        }
        default: {
            luaX_syntaxerror(ls, "unexpected symbol");
        }
    }
}

/// @brief 后缀的表达式, 基本表达式{+后续}, 基本表达示可以理解成一个变量, 后缀的表达式可以为 ( . [ : {
static void suffixedexp(LexState* ls, expdesc* v) {
    /* suffixedexp -> primaryexp { '.' NAME | '[' exp ']' | ':' NAME funcargs | funcargs } */
    FuncState* fs = ls->fs;
    int line = ls->linenumber;
    primaryexp(ls, v);
    for (;;) {
        switch (ls->t.token) {
            case '.': { /* fieldsel */ fieldsel(ls, v); break;
            }
            case '[': { /* '[' exp ']' */
                expdesc key;
                luaK_exp2anyregup(fs, v);
                yindex(ls, &key);
                luaK_indexed(fs, v, &key);
                break;
            }
            case ':': { /* ':' NAME funcargs */
                expdesc key;
                luaX_next(ls);
                codename(ls, &key);
                luaK_self(fs, v, &key);
                funcargs(ls, v, line);
                break;
            }
            case '(':
            case TK_STRING:
            case '{': { /* funcargs */
                luaK_exp2nextreg(fs, v);
                funcargs(ls, v, line);
                break;
            }
            default: return;
        }
    }
}

/// @brief 分析当前表达式, 同时取下一个 token
static void simpleexp(LexState* ls, expdesc* v) {
    /* simpleexp -> FLT | INT | STRING | NIL | TRUE | FALSE | ... | constructor | FUNCTION body | suffixedexp */
    switch (ls->t.token) {
        case TK_FLT: { // 就是浮点数
            init_exp(v, VKFLT, 0);
            v->u.nval = ls->t.seminfo.r;
            break;
        }
        case TK_INT: { // 就是整数
            init_exp(v, VKINT, 0);
            v->u.ival = ls->t.seminfo.i;
            break;
        }
        case TK_STRING: { // VKSTR 类型, 字符串
            codestring(v, ls->t.seminfo.ts);
            break;
        }
        case TK_NIL: { // nil
            init_exp(v, VNIL, 0);
            break;
        }
        case TK_TRUE: { // true
            init_exp(v, VTRUE, 0);
            break;
        }
        case TK_FALSE: { // false
            init_exp(v, VFALSE, 0);
            break;
        }
        case TK_DOTS: { /* vararg */
            FuncState* fs = ls->fs;
            // 当前函数必须是可变长函数
            check_condition(ls, fs->f->is_vararg, "cannot use '...' outside a vararg function");
            init_exp(v, VVARARG, luaK_codeABC(fs, OP_VARARG, 0, 0, 1));
            break;
        }
        case '{': { /* constructor */
            constructor(ls, v); // 表
            return;
        }
        case TK_FUNCTION: {
            luaX_next(ls);
            body(ls, v, 0, ls->linenumber);
            return;
        }
        default: {
            suffixedexp(ls, v);
            return;
        }
    }
    luaX_next(ls);
}

/// @brief 返回当前 token 对应的一元操作符的枚举
static UnOpr getunopr(int op) {
    switch (op) {
        case TK_NOT: return OPR_NOT;
        case '-': return OPR_MINUS;
        case '~': return OPR_BNOT;
        case '#': return OPR_LEN;
        default: return OPR_NOUNOPR;
    }
}

static BinOpr getbinopr(int op) {
    switch (op) {
        case '+': return OPR_ADD;
        case '-': return OPR_SUB;
        case '*': return OPR_MUL;
        case '%': return OPR_MOD;
        case '^': return OPR_POW;
        case '/': return OPR_DIV;
        case TK_IDIV: return OPR_IDIV;
        case '&': return OPR_BAND;
        case '|': return OPR_BOR;
        case '~': return OPR_BXOR;
        case TK_SHL: return OPR_SHL;
        case TK_SHR: return OPR_SHR;
        case TK_CONCAT: return OPR_CONCAT;
        case TK_NE: return OPR_NE;
        case TK_EQ: return OPR_EQ;
        case '<': return OPR_LT;
        case TK_LE: return OPR_LE;
        case '>': return OPR_GT;
        case TK_GE: return OPR_GE;
        case TK_AND: return OPR_AND;
        case TK_OR: return OPR_OR;
        default: return OPR_NOBINOPR;
    }
}

/*
** Priority table for binary operators.
*/
static const struct {
    lu_byte left; /* left priority for each binary operator */
    lu_byte right; /* right priority */
} priority[] = {
    /* ORDER OPR */
    {10, 10}, {10, 10}, /* '+' '-' */
    {11, 11}, {11, 11}, /* '*' '%' */
    {14, 13}, /* '^' (right associative) */
    {11, 11}, {11, 11}, /* '/' '//' */
    {6, 6},   {4, 4},   {5, 5}, /* '&' '|' '~' */
    {7, 7},   {7, 7}, /* '<<' '>>' */
    {9, 8}, /* '..' (right associative) */
    {3, 3},   {3, 3},   {3, 3}, /* ==, <, <= */
    {3, 3},   {3, 3},   {3, 3}, /* ~=, >, >= */
    {2, 2},   {1, 1} /* and, or */
};

#define UNARY_PRIORITY 12 /* priority for unary operators */

/// @brief 在递归调用 \r
/// subexpr -> (simpleexp | unop subexpr) { binop subexpr }
/// where 'binop' is any binary operator with a priority higher than 'limit'
static BinOpr subexpr(LexState* ls, expdesc* v, int limit) {
    BinOpr op; // 两元操作符
    UnOpr uop; // 一元操作符
    enterlevel(ls); // 递归层数标记, 防止进入太多层
    uop = getunopr(ls->t.token); // 看看操作符是不是一元操作符
    if (uop != OPR_NOUNOPR) { /* prefix (unary) operator? */
        int line = ls->linenumber;
        luaX_next(ls); /* skip operator */
        subexpr(ls, v, UNARY_PRIORITY);
        luaK_prefix(ls->fs, uop, v, line);
    } else
        simpleexp(ls, v);
    /* expand while operators have priorities higher than 'limit' */
    op = getbinopr(ls->t.token);
    while (op != OPR_NOBINOPR && priority[op].left > limit) {
        expdesc v2;
        BinOpr nextop;
        int line = ls->linenumber;
        luaX_next(ls); /* skip operator */
        luaK_infix(ls->fs, op, v);
        /* read sub-expression with higher priority */
        nextop = subexpr(ls, &v2, priority[op].right); // 只有这里在乎 subexpr 的返回值
        luaK_posfix(ls->fs, op, v, &v2, line);
        op = nextop;
    }
    leavelevel(ls);
    return op; /* return first untreated operator */
}

/// @brief 解析一个表达式
static void expr(LexState* ls, expdesc* v) { //
    subexpr(ls, v, 0);
}

/* }==================================================================== */

/*
** {======================================================================
** Rules for Statements
** =======================================================================
*/

/// @brief 进入一个语句块, 分析完成后, 再离开
static void block(LexState* ls) {
    /* block -> statlist */
    FuncState* fs = ls->fs;
    BlockCnt bl;
    enterblock(fs, &bl, 0);
    statlist(ls);
    leaveblock(fs);
}

// structure to chain all variables in the left-hand side of an assignment
struct LHS_assign {
    struct LHS_assign* prev;
    expdesc v; /* variable (global, local, upvalue, or indexed) */
};

/*
** check whether, in an assignment to an upvalue/local variable, the
** upvalue/local variable is begin used in a previous assignment to a
** table. If so, save original upvalue/local value in a safe place and
** use this safe copy in the previous assignment.
*/
static void check_conflict(LexState* ls, struct LHS_assign* lh, expdesc* v) {
    FuncState* fs = ls->fs;
    int extra = fs->freereg; /* eventual position to save local variable */
    int conflict = 0;
    for (; lh; lh = lh->prev) { /* check all previous assignments */
        if (vkisindexed(lh->v.k)) { /* assignment to table field? */
            if (lh->v.k == VINDEXUP) { /* is table an upvalue? */
                if (v->k == VUPVAL && lh->v.u.ind.t == v->u.info) {
                    conflict = 1; /* table is the upvalue being assigned now */
                    lh->v.k = VINDEXSTR;
                    lh->v.u.ind.t = extra; /* assignment will use safe copy */
                }
            } else { /* table is a register */
                if (v->k == VLOCAL && lh->v.u.ind.t == v->u.var.ridx) {
                    conflict = 1; /* table is the local being assigned now */
                    lh->v.u.ind.t = extra; /* assignment will use safe copy */
                }
                /* is index the local being assigned? */
                if (lh->v.k == VINDEXED && v->k == VLOCAL && lh->v.u.ind.idx == v->u.var.ridx) {
                    conflict = 1;
                    lh->v.u.ind.idx = extra; /* previous assignment will use safe copy */
                }
            }
        }
    }
    if (conflict) {
        /* copy upvalue/local value to a temporary (in position 'extra') */
        if (v->k == VLOCAL)
            luaK_codeABC(fs, OP_MOVE, extra, v->u.var.ridx, 0);
        else
            luaK_codeABC(fs, OP_GETUPVAL, extra, v->u.info, 0);
        luaK_reserveregs(fs, 1);
    }
}

/*
** Parse and compile a multiple assignment. The first "variable"
** (a 'suffixedexp') was already read by the caller.
**
** assignment -> suffixedexp restassign
** restassign -> ',' suffixedexp restassign | '=' explist
*/
static void restassign(LexState* ls, struct LHS_assign* lh, int nvars) {
    expdesc e;
    check_condition(ls, vkisvar(lh->v.k), "syntax error");
    check_readonly(ls, &lh->v);
    if (testnext(ls, ',')) {
        /* restassign -> ',' suffixedexp restassign */
        struct LHS_assign nv;
        nv.prev = lh;
        suffixedexp(ls, &nv.v);
        if (!vkisindexed(nv.v.k)) check_conflict(ls, lh, &nv.v);
        enterlevel(ls); /* control recursion depth */
        restassign(ls, &nv, nvars + 1);
        leavelevel(ls);
    } else {
        /* restassign -> '=' explist */
        int nexps;
        checknext(ls, '=');
        nexps = explist(ls, &e);
        if (nexps != nvars)
            adjust_assign(ls, nvars, nexps, &e);
        else {
            luaK_setoneret(ls->fs, &e); /* close last expression */
            luaK_storevar(ls->fs, &lh->v, &e);
            return; /* avoid default */
        }
    }
    init_exp(&e, VNONRELOC, ls->fs->freereg - 1); /* default assignment */
    luaK_storevar(ls->fs, &lh->v, &e);
}

/// @brief 解析条件表达式
static int cond(LexState* ls) {
    /* cond -> exp */
    expdesc v;
    expr(ls, &v); /* read condition */
    if (v.k == VNIL) v.k = VFALSE; /* 'falses' are all equal here */
    luaK_goiftrue(ls->fs, &v);
    return v.f;
}

static void gotostat(LexState* ls) {
    FuncState* fs = ls->fs;
    int line = ls->linenumber;
    TString* name = str_checkname(ls); /* label's name */
    Labeldesc* lb = findlabel(ls, name);
    if (lb == NULL) /* no label? */
        /* forward jump; will be resolved when the label is declared */
        newgotoentry(ls, name, line, luaK_jump(fs));
    else { /* found a label */
        /* backward jump; will be resolved here */
        int lblevel = reglevel(fs, lb->nactvar); /* label level */
        if (luaY_nvarstack(fs) > lblevel) /* leaving the scope of a variable? */
            luaK_codeABC(fs, OP_CLOSE, lblevel, 0, 0);
        /* create jump and link it to the label */
        luaK_patchlist(fs, luaK_jump(fs), lb->pc);
    }
}

/*
** Break statement. Semantically equivalent to "goto break".
*/
static void breakstat(LexState* ls) {
    int line = ls->linenumber;
    luaX_next(ls); /* skip break */
    newgotoentry(ls, luaS_newliteral(ls->L, "break"), line, luaK_jump(ls->fs));
}

/// @brief Check whether there is already a label with the given 'name'.
static void checkrepeated(LexState* ls, TString* name) {
    Labeldesc* lb = findlabel(ls, name);
    if (l_unlikely(lb != NULL)) { /* already defined? */
        const char* msg = "label '%s' already defined on line %d";
        msg = luaO_pushfstring(ls->L, msg, getstr(name), lb->line);
        luaK_semerror(ls, msg); /* error */
    }
}

/// @param name 标签名
static void labelstat(LexState* ls, TString* name, int line) {
    /* label -> '::' NAME '::' */
    checknext(ls, TK_DBCOLON); /* skip double colon */
    while (ls->t.token == ';' || ls->t.token == TK_DBCOLON) statement(ls); /* skip other no-op statements */
    checkrepeated(ls, name); /* check for repeated labels */
    createlabel(ls, name, line, block_follow(ls, 0));
}

static void whilestat(LexState* ls, int line) {
    /* whilestat -> WHILE cond DO block END */
    FuncState* fs = ls->fs;
    int whileinit;
    int condexit;
    BlockCnt bl;
    luaX_next(ls); /* skip WHILE */
    // while 指令在 code 中的索引, c 数组是从 0 开始的
    whileinit = luaK_getlabel(fs);
    condexit = cond(ls);
    enterblock(fs, &bl, 1);
    checknext(ls, TK_DO);
    block(ls);
    luaK_jumpto(fs, whileinit);
    check_match(ls, TK_END, TK_WHILE, line);
    leaveblock(fs);
    luaK_patchtohere(fs, condexit); /* false conditions finish the loop */
}

static void repeatstat(LexState* ls, int line) {
    /* repeatstat -> REPEAT block UNTIL cond */
    int condexit;
    FuncState* fs = ls->fs;
    int repeat_init = luaK_getlabel(fs);
    BlockCnt bl1, bl2;
    enterblock(fs, &bl1, 1); /* loop block */
    enterblock(fs, &bl2, 0); /* scope block */
    luaX_next(ls); /* skip REPEAT */
    statlist(ls);
    check_match(ls, TK_UNTIL, TK_REPEAT, line);
    condexit = cond(ls); /* read condition (inside scope block) */
    leaveblock(fs); /* finish scope */
    if (bl2.upval) { /* upvalues? */
        int exit = luaK_jump(fs); /* normal exit must jump over fix */
        luaK_patchtohere(fs, condexit); /* repetition must close upvalues */
        luaK_codeABC(fs, OP_CLOSE, reglevel(fs, bl2.nactvar), 0, 0);
        condexit = luaK_jump(fs); /* repeat after closing upvalues */
        luaK_patchtohere(fs, exit); /* normal exit comes to here */
    }
    luaK_patchlist(fs, condexit, repeat_init); /* close the loop */
    leaveblock(fs); /* finish loop */
}

/*
** Read an expression and generate code to put its results in next
** stack slot.
**
*/
static void exp1(LexState* ls) {
    expdesc e;
    expr(ls, &e);
    luaK_exp2nextreg(ls->fs, &e);
    lua_assert(e.k == VNONRELOC);
}

/*
** Fix for instruction at position 'pc' to jump to 'dest'.
** (Jump addresses are relative in Lua). 'back' true means
** a back jump.
*/
static void fixforjump(FuncState* fs, int pc, int dest, int back) {
    Instruction* jmp = &fs->f->code[pc];
    int offset = dest - (pc + 1);
    if (back) offset = -offset;
    if (l_unlikely(offset > MAXARG_Bx)) luaX_syntaxerror(fs->ls, "control structure too long");
    SETARG_Bx(*jmp, offset);
}

/*
** Generate code for a 'for' loop.
*/
static void forbody(LexState* ls, int base, int line, int nvars, int isgen) {
    /* forbody -> DO block */
    static const OpCode forprep[2] = {OP_FORPREP, OP_TFORPREP};
    static const OpCode forloop[2] = {OP_FORLOOP, OP_TFORLOOP};
    BlockCnt bl;
    FuncState* fs = ls->fs;
    int prep, endfor;
    checknext(ls, TK_DO);
    prep = luaK_codeABx(fs, forprep[isgen], base, 0);
    enterblock(fs, &bl, 0); /* scope for declared variables */
    adjustlocalvars(ls, nvars);
    luaK_reserveregs(fs, nvars);
    block(ls);
    leaveblock(fs); /* end of scope for declared variables */
    fixforjump(fs, prep, luaK_getlabel(fs), 0);
    if (isgen) { /* generic for? */
        luaK_codeABC(fs, OP_TFORCALL, base, 0, nvars);
        luaK_fixline(fs, line);
    }
    endfor = luaK_codeABx(fs, forloop[isgen], base, 0);
    fixforjump(fs, endfor, prep + 1, 1);
    luaK_fixline(fs, line);
}

static void fornum(LexState* ls, TString* varname, int line) {
    /* fornum -> NAME = exp,exp[,exp] forbody */
    FuncState* fs = ls->fs;
    int base = fs->freereg; // 当前 forbody 的 base
    // 申请 3 个临时变量与 1 个正常变量, 如果超过 MAXVARS, 报错
    new_localvarliteral(ls, "(for state)");
    new_localvarliteral(ls, "(for state)");
    new_localvarliteral(ls, "(for state)");
    new_localvar(ls, varname);
    checknext(ls, '=');
    exp1(ls); /* initial value */
    checknext(ls, ',');
    exp1(ls); /* limit */
    if (testnext(ls, ','))
        exp1(ls); /* optional step */
    else { /* default step = 1 */
        luaK_int(fs, fs->freereg, 1);
        luaK_reserveregs(fs, 1);
    }
    adjustlocalvars(ls, 3); /* control variables */
    forbody(ls, base, line, 1, 0);
}

static void forlist(LexState* ls, TString* indexname) {
    /* forlist -> NAME {,NAME} IN explist forbody */
    FuncState* fs = ls->fs;
    expdesc e;
    int nvars = 5; /* gen, state, control, toclose, 'indexname' */
    int line;
    int base = fs->freereg;
    /* create control variables */
    new_localvarliteral(ls, "(for state)");
    new_localvarliteral(ls, "(for state)");
    new_localvarliteral(ls, "(for state)");
    new_localvarliteral(ls, "(for state)");
    /* create declared variables */
    new_localvar(ls, indexname);
    while (testnext(ls, ',')) {
        new_localvar(ls, str_checkname(ls));
        nvars++;
    }
    checknext(ls, TK_IN);
    line = ls->linenumber;
    adjust_assign(ls, 4, explist(ls, &e), &e);
    adjustlocalvars(ls, 4); /* control variables */
    marktobeclosed(fs); /* last control var. must be closed */
    luaK_checkstack(fs, 3); /* extra space to call generator */
    forbody(ls, base, line, nvars - 4, 1);
}

static void forstat(LexState* ls, int line) {
    /* forstat -> FOR (fornum | forlist) END */
    FuncState* fs = ls->fs;
    TString* varname;
    BlockCnt bl;
    enterblock(fs, &bl, 1); /* scope for loop and control variables */
    luaX_next(ls); /* skip 'for' */
    varname = str_checkname(ls); /* first variable name */
    switch (ls->t.token) {
        case '=': fornum(ls, varname, line); break;
        case ',':
        case TK_IN: forlist(ls, varname); break;
        default: luaX_syntaxerror(ls, "'=' or 'in' expected");
    }
    check_match(ls, TK_END, TK_FOR, line);
    leaveblock(fs); /* loop scope ('break' jumps to this point) */
}

static void test_then_block(LexState* ls, int* escapelist) {
    /* test_then_block -> [IF | ELSEIF] cond THEN block */
    BlockCnt bl; // 生成一个 block
    FuncState* fs = ls->fs;
    expdesc v; // 表达式描述
    int jf; /* instruction to skip 'then' code (if condition is false) */
    luaX_next(ls); /* skip IF or ELSEIF */
    expr(ls, &v); /* read condition */
    checknext(ls, TK_THEN); // 条件表达式后面需要一个 then
    if (ls->t.token == TK_BREAK) { /* 'if x then break' ? */
        int line = ls->linenumber;
        luaK_goiffalse(ls->fs, &v); /* will jump if condition is true */
        luaX_next(ls); /* skip 'break' */
        enterblock(fs, &bl, 0); /* must enter block before 'goto' */
        newgotoentry(ls, luaS_newliteral(ls->L, "break"), line, v.t);
        while (testnext(ls, ';')) {} /* skip semicolons */
        if (block_follow(ls, 0)) { /* jump is the entire block? */
            leaveblock(fs);
            return; /* and that is it */
        } else /* must skip over 'then' part if condition is false */
            jf = luaK_jump(fs);
    } else { /* regular case (not a break) */
        luaK_goiftrue(ls->fs, &v); /* skip over block if condition is false */
        enterblock(fs, &bl, 0);
        jf = v.f;
    }
    statlist(ls); /* 'then' part */
    leaveblock(fs);
    if (ls->t.token == TK_ELSE || ls->t.token == TK_ELSEIF) /* followed by 'else'/'elseif'? */
        luaK_concat(fs, escapelist, luaK_jump(fs)); /* must jump over it */
    luaK_patchtohere(fs, jf);
}

static void ifstat(LexState* ls, int line) {
    /* ifstat -> IF cond THEN block {ELSEIF cond THEN block} [ELSE block] END */
    FuncState* fs = ls->fs;
    int escapelist = NO_JUMP; /* exit list for finished parts */
    test_then_block(ls, &escapelist); /* IF cond THEN block */
    while (ls->t.token == TK_ELSEIF) // 如果有 elseif 再进入 test_then_block
        test_then_block(ls, &escapelist); /* ELSEIF cond THEN block */
    if (testnext(ls, TK_ELSE)) block(ls); /* 'else' part */
    check_match(ls, TK_END, TK_IF, line);
    luaK_patchtohere(fs, escapelist); /* patch escape list to 'if' end */
}

static void localfunc(LexState* ls) {
    expdesc b; // 之后 codeclosure 的描述结构
    FuncState* fs = ls->fs;
    int fvar = fs->nactvar; /* function's variable index */
    new_localvar(ls, str_checkname(ls)); /* new local variable */
    adjustlocalvars(ls, 1); /* enter its scope */
    body(ls, &b, 0, ls->linenumber); /* function created in next register */
    /* debug information will only see the variable after this point! */
    localdebuginfo(fs, fvar)->startpc = fs->pc;
}

/// @brief 如果脚本显式指明变量类型, 否则都使用 VDKREG
static int getlocalattribute(LexState* ls) {
    /* ATTRIB -> ['<' Name '>'] */
    if (testnext(ls, '<')) {
        const char* attr = getstr(str_checkname(ls));
        checknext(ls, '>');
        if (strcmp(attr, "const") == 0)
            return RDKCONST; /* read-only variable */
        else if (strcmp(attr, "close") == 0)
            return RDKTOCLOSE; /* to-be-closed variable */
        else
            luaK_semerror(ls, luaO_pushfstring(ls->L, "unknown attribute '%s'", attr));
    }
    return VDKREG; /* regular variable */
}

/// @brief 目前用不到, level 都是 -1
static void checktoclose(FuncState* fs, int level) {
    if (level != -1) { /* is there a to-be-closed variable? */
        marktobeclosed(fs);
        luaK_codeABC(fs, OP_TBC, reglevel(fs, level), 0, 0);
    }
}

/// @brief 用 local 定义的普通变量(不包括 local function ...)
static void localstat(LexState* ls) {
    /* stat -> LOCAL NAME ATTRIB { ',' NAME ATTRIB } ['=' explist] */
    FuncState* fs = ls->fs;
    int toclose = -1; /* index of to-be-closed variable (if any) */
    Vardesc* var; /* last variable */
    int vidx, kind; /* index and kind of last variable */
    int nvars = 0; // local 后面跟的变量数
    int nexps; // = 后面表达式的个数
    expdesc e;
    do { // 现在只是解析到变量名, 知道有这么一个名字的变量
        vidx = new_localvar(ls, str_checkname(ls));
        kind = getlocalattribute(ls); // 目前返回的都是 VDKREG
        getlocalvardesc(fs, vidx)->vd.kind = kind; // 所以这里都显示变量
        // 这里是不会进入的
        if (kind == RDKTOCLOSE) { /* to-be-closed? */
            if (toclose != -1) /* one already present? */
                luaK_semerror(ls, "multiple to-be-closed variables in local list");
            toclose = fs->nactvar + nvars;
        }
        nvars++;
    } while (testnext(ls, ','));
    if (testnext(ls, '='))
        nexps = explist(ls, &e); // 除了最后一个表达式, 其他已经分配到了寄存器, e 记录最后一个表达式
    else {
        e.k = VVOID;
        nexps = 0;
    }
    var = getlocalvardesc(fs, vidx); /* get last variable */
    /* no adjustments? && last variable is const? && compile-time constant? */
    if (nvars == nexps && var->vd.kind == RDKCONST && luaK_exp2const(fs, &e, &var->k)) {
        var->vd.kind = RDKCTC; /* variable is a compile-time constant */
        adjustlocalvars(ls, nvars - 1); /* exclude last variable */
        fs->nactvar++; /* but count it */
    } else {
        adjust_assign(ls, nvars, nexps, &e); // 给最后一个表达式分配寄存器
        adjustlocalvars(ls, nvars);
    }
    checktoclose(fs, toclose); // 不用管这个
}

/// @brief 解析函数名, 如果最后使用 :, 就是方法
static int funcname(LexState* ls, expdesc* v) {
    /* funcname -> NAME {fieldsel} [':' NAME] */
    int ismethod = 0;
    singlevar(ls, v);
    while (ls->t.token == '.') //
        fieldsel(ls, v);
    if (ls->t.token == ':') {
        ismethod = 1;
        fieldsel(ls, v);
    }
    return ismethod;
}

static void funcstat(LexState* ls, int line) {
    /* funcstat -> FUNCTION funcname body */
    int ismethod;
    expdesc v, b;
    luaX_next(ls); /* skip FUNCTION */
    ismethod = funcname(ls, &v);
    body(ls, &b, ismethod, line);
    check_readonly(ls, &v);
    luaK_storevar(ls->fs, &v, &b);
    luaK_fixline(ls->fs, line); /* definition "happens" in the first line */
}

/// @brief 处理函数调用或赋值操作
static void exprstat(LexState* ls) {
    /* stat -> func | assignment */
    FuncState* fs = ls->fs;
    struct LHS_assign v;
    suffixedexp(ls, &v.v); // 处理第一个 token
    if (ls->t.token == '=' || ls->t.token == ',') {
        /* stat -> assignment ? */
        v.prev = NULL; // 链头的 prev 为 NULL
        restassign(ls, &v, 1);
    } else {
        /* stat -> func */
        Instruction* inst;
        check_condition(ls, v.v.k == VCALL, "syntax error");
        inst = &getinstruction(fs, &v.v);
        // 只是函数调用, 所以不需要返回值
        SETARG_C(*inst, 1); /* call statement uses no results */
    }
}

static void retstat(LexState* ls) {
    /* stat -> RETURN [explist] [';'] */
    FuncState* fs = ls->fs;
    expdesc e;
    int nret; /* number of values being returned */
    int first = luaY_nvarstack(fs); /* first slot to be returned */
    if (block_follow(ls, 1) || ls->t.token == ';')
        nret = 0; /* return no values */
    else {
        nret = explist(ls, &e); /* optional return values */
        if (hasmultret(e.k)) {
            luaK_setmultret(fs, &e);
            if (e.k == VCALL && nret == 1 && !fs->bl->insidetbc) { /* tail call? */
                SET_OPCODE(getinstruction(fs, &e), OP_TAILCALL);
                lua_assert(GETARG_A(getinstruction(fs, &e)) == luaY_nvarstack(fs));
            }
            nret = LUA_MULTRET; /* return all values */
        } else {
            if (nret == 1) /* only one single value? */
                first = luaK_exp2anyreg(fs, &e); /* can use original slot */
            else { /* values must go to the top of the stack */
                luaK_exp2nextreg(fs, &e);
                lua_assert(nret == fs->freereg - first);
            }
        }
    }
    luaK_ret(fs, first, nret);
    testnext(ls, ';'); /* skip optional semicolon */
}

static void statement(LexState* ls) {
    int line = ls->linenumber; /* may be needed for error messages */
    enterlevel(ls);
    switch (ls->t.token) {
        case ';': {
            /* stat -> ';' (empty statement) */
            luaX_next(ls); /* skip ';' */
            break;
        }
        case TK_IF: {
            /* stat -> ifstat */
            ifstat(ls, line);
            break;
        }
        case TK_WHILE: {
            /* stat -> whilestat */
            whilestat(ls, line);
            break;
        }
        case TK_DO: {
            /* stat -> DO block END */
            luaX_next(ls); /* skip DO */
            block(ls);
            check_match(ls, TK_END, TK_DO, line);
            break;
        }
        case TK_FOR: {
            /* stat -> forstat */
            forstat(ls, line);
            break;
        }
        case TK_REPEAT: {
            /* stat -> repeatstat */
            repeatstat(ls, line);
            break;
        }
        case TK_FUNCTION: {
            /* stat -> funcstat */
            funcstat(ls, line); // 非局部函数走这里
            break;
        }
        case TK_LOCAL: {
            /* stat -> localstat */
            luaX_next(ls); /* skip LOCAL */
            if (testnext(ls, TK_FUNCTION)) /* local function? */
                localfunc(ls); // 如果是 local function ... 就进入这里处理
            else
                localstat(ls); // 如果是 local 普通变量则进入这里
            break;
        }
        case TK_DBCOLON: {
            /* stat -> label */
            luaX_next(ls); /* skip double colon */
            labelstat(ls, str_checkname(ls), line);
            break;
        }
        case TK_RETURN: {
            /* stat -> retstat */
            luaX_next(ls); /* skip RETURN */
            retstat(ls);
            break;
        }
        case TK_BREAK: {
            /* stat -> breakstat */
            breakstat(ls);
            break;
        }
        case TK_GOTO: {
            /* stat -> 'goto' NAME */
            luaX_next(ls); /* skip 'goto' */
            gotostat(ls);
            break;
        }
        default: {
            /* stat -> func | assignment */
            exprstat(ls);
            break;
        }
    }
    lua_assert(ls->fs->f->maxstacksize >= ls->fs->freereg && ls->fs->freereg >= luaY_nvarstack(ls->fs));
    // 一个代码块解析完毕之后, 要解析内存代码使用寄存器
    ls->fs->freereg = luaY_nvarstack(ls->fs); /* free registers */
    leavelevel(ls);
}

/* }====================================================================== */

/*
** compiles the main function, which is a regular vararg function with an upvalue named LUA_ENV
*/
static void mainfunc(LexState* ls, FuncState* fs) {
    BlockCnt bl; // 主函数的 block
    Upvaldesc* env; // 主函数的 _ENV
    open_func(ls, fs, &bl); // 主函数的 prev 为 NULL
    // 主函数的第一条指令, 主函数都是变长参数
    setvararg(fs, 0); /* main function is always declared vararg */
    env = allocupvalue(fs); /* ...set environment upvalue */
    env->instack = 1; // 在主函数的栈上
    env->idx = 0; // 索引
    env->kind = VDKREG; // 普通的寄存器变量
    env->name = ls->envn; // 在 luaX_setinput() 中赋值的, 所以主闭包的第一个 upvalue 就是 _ENV
    luaC_objbarrier(ls->L, fs->f, env->name);
    luaX_next(ls); /* read first token */
    statlist(ls); /* parse main body */
    check(ls, TK_EOS); // 看看 lua 脚本是不是读取完毕了
    close_func(ls);
}

/// @brief 把 lua 文件解析成一个 lua 闭包
LClosure* luaY_parser(lua_State* L, ZIO* z, Mbuffer* buff, Dyndata* dyd, const char* name, int firstchar) {
    LexState lexstate;
    FuncState funcstate;
    // 主闭包只有一个 upvalue, 那就是 _ENV
    LClosure* cl = luaF_newLclosure(L, 1); /* create main closure */
    setclLvalue2s(L, L->top, cl); /* anchor it (to avoid being collected) */
    luaD_inctop(L);
    lexstate.h = luaH_new(L); /* create table for scanner */
    sethvalue2s(L, L->top, lexstate.h); /* anchor it */
    luaD_inctop(L);
    funcstate.f = cl->p = luaF_newproto(L); // 主闭包的原型
    luaC_objbarrier(L, cl, cl->p);
    funcstate.f->source = luaS_new(L, name); /* create and anchor TString */
    luaC_objbarrier(L, funcstate.f, funcstate.f->source);
    lexstate.buff = buff;
    lexstate.dyd = dyd;
    dyd->actvar.n = dyd->gt.n = dyd->label.n = 0;
    luaX_setinput(L, &lexstate, z, funcstate.f->source, firstchar);
    mainfunc(&lexstate, &funcstate); // 主函数 就是最最外层的闭包
    lua_assert(!funcstate.prev && funcstate.nups == 1 && !lexstate.fs);
    /* all scopes should be correctly finished */
    lua_assert(dyd->actvar.n == 0 && dyd->gt.n == 0 && dyd->label.n == 0);
    L->top--; /* remove scanner's table */
    return cl; /* closure is on the stack, too */
}
