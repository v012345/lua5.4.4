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

/* maximum number of local variables per function (must be smaller
   than 250, due to the bytecode format) */
#define MAXVARS 200

#define hasmultret(k) ((k) == VCALL || (k) == VVARARG)

/* because all strings are unified by the scanner, the parser
   can use pointer equality for string equality */
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

// v 大于 l 时报错
static void checklimit(FuncState* fs, int v, int l, const char* what) {
    if (v > l) //
        errorlimit(fs, l, what);
}

/*
** Test whether next token is 'c'; if so, skip it.
*/
static int testnext(LexState* ls, int c) {
    if (ls->t.token == c) {
        luaX_next(ls);
        return 1;
    } else
        return 0;
}

/*
** Check that next token is 'c'.
*/
static void check(LexState* ls, int c) {
    if (ls->t.token != c) //
        error_expected(ls, c);
}

/*
** Check that next token is 'c' and skip it.
*/
static void checknext(LexState* ls, int c) {
    check(ls, c);
    luaX_next(ls);
}

#define check_condition(ls, c, msg)                                                                                                                                                                    \
    {                                                                                                                                                                                                  \
        if (!(c)) luaX_syntaxerror(ls, msg);                                                                                                                                                           \
    }

/*
** Check that next token is 'what' and skip it. In case of error,
** raise an error that the expected 'what' should match a 'who'
** in line 'where' (if that is not the current line).
*/
static void check_match(LexState* ls, int what, int who, int where) {
    if (l_unlikely(!testnext(ls, what))) {
        if (where == ls->linenumber) /* all in the same line? */
            error_expected(ls, what); /* do not need a complex message */
        else { //
            luaX_syntaxerror(ls, luaO_pushfstring(ls->L, "%s expected (to close %s at line %d)", luaX_token2str(ls, what), luaX_token2str(ls, who), where));
        }
    }
}

static TString* str_checkname(LexState* ls) {
    TString* ts;
    check(ls, TK_NAME);
    ts = ls->t.seminfo.ts;
    luaX_next(ls);
    return ts;
}

static void init_exp(expdesc* e, expkind k, int i) {
    e->f = e->t = NO_JUMP;
    e->k = k;
    e->u.info = i;
}

static void codestring(expdesc* e, TString* s) {
    e->f = e->t = NO_JUMP;
    e->k = VKSTR; // 说明还没有放到常量表里
    e->u.strval = s;
}

// 非常明确下一个 token 就是 TK_NAME, 直接用 e 来接收这个 TK_NAME
// 用于表的 key
static void codename(LexState* ls, expdesc* e) { //
    codestring(e, str_checkname(ls));
}

/*
** Register a new local variable in the active 'Proto' (for debug
** information).
*/
static int registerlocalvar(LexState* ls, FuncState* fs, TString* varname) {
    Proto* f = fs->f;
    int oldsize = f->sizelocvars;
    luaM_growvector(ls->L, f->locvars, fs->ndebugvars, f->sizelocvars, LocVar, SHRT_MAX, "local variables");
    while (oldsize < f->sizelocvars) f->locvars[oldsize++].varname = NULL;
    f->locvars[fs->ndebugvars].varname = varname;
    f->locvars[fs->ndebugvars].startpc = fs->pc;
    luaC_objbarrier(ls->L, f, varname);
    return fs->ndebugvars++;
}

/*
** Create a new local variable with the given 'name'. Return its index
** in the function.
*/
static int new_localvar(LexState* ls, TString* name) {
    // 在 dyd->actvar 中注册一个局部变量, 变量名为 name
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

#define new_localvarliteral(ls, v) new_localvar(ls, luaX_newstring(ls, "" v, (sizeof(v) / sizeof(char)) - 1));

/*
** Return the "variable description" (Vardesc) of a given variable.
** (Unless noted otherwise, all variables are referred to by their
** compiler indices.)
*/
static Vardesc* getlocalvardesc(FuncState* fs, int vidx) { //
    // 通过索引, 拿到 fs 的指定局部变量
    return &fs->ls->dyd->actvar.arr[fs->firstlocal + vidx];
}

/*
** Convert 'nvar', a compiler index level, to its corresponding
** register. For that, search for the highest variable below that level
** that is in a register and uses its register index ('ridx') plus one.
*/
static int reglevel(FuncState* fs, int nvar) {
    // 还是没有理解如果处理 <const> 的
    while (nvar-- > 0) {
        Vardesc* vd = getlocalvardesc(fs, nvar); /* get previous variable */
        if (vd->vd.kind != RDKCTC) /* is in a register? */
            return vd->vd.ridx + 1;
    }
    return 0; /* no variables in registers */
}

/*
** Return the number of variables in the register stack for the given
** function.
*/
int luaY_nvarstack(FuncState* fs) {
    // 返回当前函数在寄存器中的变量的个数
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

/*
** Create an expression representing variable 'vidx'
*/
static void init_var(FuncState* fs, expdesc* e, int vidx) {
    e->f = e->t = NO_JUMP;
    e->k = VLOCAL;
    e->u.var.vidx = vidx;
    e->u.var.ridx = getlocalvardesc(fs, vidx)->vd.ridx;
}

/*
** Raises an error if variable described by 'e' is read only
*/
static void check_readonly(LexState* ls, expdesc* e) {
    // 在赋值操作中(包括定义函数)检查变量是不是只读变量
    FuncState* fs = ls->fs;
    TString* varname = NULL; /* to be set if variable is const */
    switch (e->k) {
        case VCONST: { // 如果变量是 RDKCTC , 那么表达示类型就是 VCONST
            varname = ls->dyd->actvar.arr[e->u.info].vd.name;
            break;
        }
        case VLOCAL: {
            // 如果 <const> 没有被编译为 RDKCTC, 在 searchvar 时
            // 会被当做 VLOCAL 返回, 但是本质上是 RDKCONST, 就是常量, 所以不可被更改
            Vardesc* vardesc = getlocalvardesc(fs, e->u.var.vidx);
            if (vardesc->vd.kind != VDKREG) /* not a regular variable? */
                varname = vardesc->vd.name;
            break;
        }
        case VUPVAL: {
            // 如果使用外层函数的常量, 就要在这里检查一下
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

/*
** Start the scope for the last 'nvars' created variables.
*/
static void adjustlocalvars(LexState* ls, int nvars) {
    // nvars 新增加局部变量的个数
    FuncState* fs = ls->fs;
    int reglevel = luaY_nvarstack(fs);
    int i;
    for (i = 0; i < nvars; i++) {
        int vidx = fs->nactvar++;
        Vardesc* var = getlocalvardesc(fs, vidx);
        var->vd.ridx = reglevel++; // 变量在寄存器中的位置
        var->vd.pidx = registerlocalvar(ls, fs, var->vd.name);
    }
}

/*
** Close the scope for all variables up to level 'tolevel'.
** (debug info.)
*/
static void removevars(FuncState* fs, int tolevel) {
    // 真的是把局部变量的数变成 tolevel
    fs->ls->dyd->actvar.n -= (fs->nactvar - tolevel);
    while (fs->nactvar > tolevel) {
        LocVar* var = localdebuginfo(fs, --fs->nactvar);
        if (var) /* does it have debug information? */
            var->endpc = fs->pc; // 局部变量生命周期结束
    }
}

/*
** Search the upvalues of the function 'fs' for one
** with the given 'name'.
*/
static int searchupvalue(FuncState* fs, TString* name) {
    int i;
    Upvaldesc* up = fs->f->upvalues;
    for (i = 0; i < fs->nups; i++) {
        if (eqstr(up[i].name, name)) //
            return i;
    }
    return -1; /* not found */
}

static Upvaldesc* allocupvalue(FuncState* fs) {
    Proto* f = fs->f;
    int oldsize = f->sizeupvalues;
    checklimit(fs, fs->nups + 1, MAXUPVAL, "upvalues");
    luaM_growvector(fs->ls->L, f->upvalues, fs->nups, f->sizeupvalues, Upvaldesc, MAXUPVAL, "upvalues");
    while (oldsize < f->sizeupvalues) f->upvalues[oldsize++].name = NULL;
    return &f->upvalues[fs->nups++];
}

static int newupvalue(FuncState* fs, TString* name, expdesc* v) {
    Upvaldesc* up = allocupvalue(fs);
    FuncState* prev = fs->prev;
    if (v->k == VLOCAL) {
        up->instack = 1;
        // 如果上值是外层的局部变量, idx 就是变量的寄存器
        up->idx = v->u.var.ridx;
        up->kind = getlocalvardesc(prev, v->u.var.vidx)->vd.kind;
        lua_assert(eqstr(name, getlocalvardesc(prev, v->u.var.vidx)->vd.name));
    } else {
        up->instack = 0;
        // 如果上值是外层的上值, idx 就是上值列表的索引
        up->idx = cast_byte(v->u.info);
        up->kind = prev->f->upvalues[v->u.info].kind;
        lua_assert(eqstr(name, prev->f->upvalues[v->u.info].name));
    }
    up->name = name;
    luaC_objbarrier(fs->ls->L, fs->f, name);
    return fs->nups - 1;
}

/*
** Look for an active local variable with the name 'n' in the
** function 'fs'. If found, initialize 'var' with it and return
** its expression kind; otherwise return -1.
*/
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

/*
** Mark block where variable at given level was defined
** (to emit close instructions later).
*/
static void markupval(FuncState* fs, int level) {
    BlockCnt* bl = fs->bl;
    while (bl->nactvar > level) // 找到变量所在的 block
        bl = bl->previous;
    bl->upval = 1; // 把变量所在的 block 标记一下有值被引用
    fs->needclose = 1;
}

/*
** Mark that current block has a to-be-closed variable.
*/
static void marktobeclosed(FuncState* fs) {
    BlockCnt* bl = fs->bl;
    bl->upval = 1; // 为什么 to-be-closed variable 发连带上值呢?
    bl->insidetbc = 1; // 这个可以理解内部有 <close> 局部变量
    fs->needclose = 1; // 这个函数要关闭, 会在 return 时调用一下 luaF_close
}

/*
** Find a variable with the given name 'n'. If it is an upvalue, add
** this upvalue into all intermediate functions. If it is a global, set
** 'var' as 'void' as a flag.
*/
static void singlevaraux(FuncState* fs, TString* n, expdesc* var, int base) {
    // 注意一下 base 的意思, 在当前 fs 的找值 base 就是 1, 不管有多少个 block
    // 只有在子函数引用外层函数时, 被引用的 block 才会被标记上
    // base 为 1 就是当前作用域, 为 0 就是在当前作用域的上级了
    if (fs == NULL) /* no more levels? */
        init_exp(var, VVOID, 0); /* default is global */
    else {
        int v = searchvar(fs, n, var); /* look up locals at current level */
        if (v >= 0) { /* found? */
            if (v == VLOCAL && !base) //
                markupval(fs, var->u.var.vidx); /* local will be used as an upval */
        } else { /* not found as local at current level; try upvalues */
            // 如果有就是返回上值描述的索引
            int idx = searchupvalue(fs, n); /* try existing upvalues */
            if (idx < 0) { /* not found? */
                singlevaraux(fs->prev, n, var, 0); /* try upper levels */
                if (var->k == VLOCAL || var->k == VUPVAL) /* local or upvalue? */
                    idx = newupvalue(fs, n, var); /* will be a new upvalue */
                else /* it is a global or a constant */
                    return; /* don't need to do anything at this level */
            }
            init_exp(var, VUPVAL, idx); /* new or old upvalue */
        }
    }
}

/*
** Find a variable with the given name 'n', handling global variables
** too.
*/
static void singlevar(LexState* ls, expdesc* var) {
    TString* varname = str_checkname(ls);
    FuncState* fs = ls->fs;
    singlevaraux(fs, varname, var, 1);
    if (var->k == VVOID) { /* global name? */
        expdesc key;
        singlevaraux(fs, ls->envn, var, 1); /* get environment variable */
        lua_assert(var->k != VVOID); /* this one must exist */
        luaK_exp2anyregup(fs, var); /* but could be a constant */
        codestring(&key, varname); /* key is variable name */
        luaK_indexed(fs, var, &key); /* env[varname] */
    }
}

/*
** Adjust the number of results from an expression list 'e' with 'nexps'
** expressions to 'nvars' values.
*/
static void adjust_assign(LexState* ls, int nvars, int nexps, expdesc* e) {
    FuncState* fs = ls->fs;
    int needed = nvars - nexps; /* extra values needed */
    if (hasmultret(e->k)) { /* last expression has multiple returns? */
        int extra = needed + 1; /* discount last expression itself */
        if (extra < 0) // 因为不确定返回个数, 如果已经不需要返回值了
            extra = 0; // 在这里告诉函数不要返回了
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
** from the list of pending gotos.
** If it jumps into the scope of some variable, raises an error.
*/
static void solvegoto(LexState* ls, int g, Labeldesc* label) {
    int i;
    Labellist* gl = &ls->dyd->gt; /* list of gotos */
    Labeldesc* gt = &gl->arr[g]; /* goto to be resolved */
    lua_assert(eqstr(gt->name, label->name));
    // 不能跳过局部变量的定义
    if (l_unlikely(gt->nactvar < label->nactvar)) /* enter some scope? */
        // 如果 goto 到 label 之间有新局部变量声明, 那么就报错
        jumpscopeerror(ls, gt);
    luaK_patchlist(ls->fs, gt->pc, label->pc);
    for (i = g; i < gl->n - 1; i++) /* remove goto from pending list */
        gl->arr[i] = gl->arr[i + 1];
    gl->n--;
}

/*
** Search for an active label with the given name.
*/
static Labeldesc* findlabel(LexState* ls, TString* name) {
    // 看看有没有标签
    int i;
    Dyndata* dyd = ls->dyd;
    /* check labels in current function for a match */
    for (i = ls->fs->firstlabel; i < dyd->label.n; i++) {
        // 找 label 是从函数开始的地方的开找
        Labeldesc* lb = &dyd->label.arr[i];
        if (eqstr(lb->name, name)) /* correct label? */
            return lb;
    }
    return NULL; /* label not found */
}

/*
** Adds a new label/goto in the corresponding list.
*/
static int newlabelentry(LexState* ls, Labellist* l, TString* name, int line, int pc) {
    int n = l->n;
    luaM_growvector(ls->L, l->arr, n, l->size, Labeldesc, SHRT_MAX, "labels/gotos");
    l->arr[n].name = name;
    l->arr[n].line = line;
    // 当标签出现时, 当前函数已经解析出来的局部变量的个数
    // 标签当然只能在一个函数内跳转啦
    // 就是用 local 修饰的变量的个数
    // 为什么要记这个, 我也不知道
    l->arr[n].nactvar = ls->fs->nactvar;
    l->arr[n].close = 0;
    l->arr[n].pc = pc;
    l->n = n + 1;
    return n;
}

static int newgotoentry(LexState* ls, TString* name, int line, int pc) { //
    // 待定位跳转
    return newlabelentry(ls, &ls->dyd->gt, name, line, pc);
}

/*
** Solves forward jumps. Check whether new label 'lb' matches any
** pending gotos in current block and solves them. Return true
** if any of the gotos need to close upvalues.
*/
static int solvegotos(LexState* ls, Labeldesc* lb) {
    Labellist* gl = &ls->dyd->gt;
    int i = ls->fs->bl->firstgoto;
    int needsclose = 0;
    while (i < gl->n) {
        if (eqstr(gl->arr[i].name, lb->name)) {
            // 如果 goto 是从外层来的, 那么如果 goto 之前如果有上值出现
            // 那么 goto 就需要加上 OP_CLOSE
            needsclose |= gl->arr[i].close; // 这个只能是从内层传出来的
            solvegoto(ls, i, lb); /* will remove 'i' from the list */
        } else
            i++;
    }
    return needsclose;
}

/*
** Create a new label with the given 'name' at the given 'line'.
** 'last' tells whether label is the last non-op statement in its
** block. Solves all pending gotos to this new label and adds
** a close instruction if necessary.
** Returns true iff it added a close instruction.
*/
static int createlabel(LexState* ls, TString* name, int line, int last) {
    FuncState* fs = ls->fs;
    Labellist* ll = &ls->dyd->label;
    int l = newlabelentry(ls, ll, name, line, luaK_getlabel(fs));
    if (last) { /* label is last no-op statement in the block? */
        // 就是说这个 label 是不是一个 block 的最后一个语句
        // 这里就是 UNTIL 有局部变量作用域的问题
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
            // 如果在当前 block 中的 goto 定义之前还有声明局部变量, 因为这些 goto 的标签还没有定义
            // 而是在 blcok 外面的下方, 所以这些 goto 在正解的情况必然会跳到外面, 从而离开当前 block
            // 而 movegotosout 是在离开 block 时调用的, 而这个是时候已经知道了是不是有值被引用
            gt->close |= bl->upval; /* jump may need a close */
        // 这里说明把 gt 的 level 修正为 block 之外
        gt->nactvar = bl->nactvar; /* update goto level */
    }
}

static void enterblock(FuncState* fs, BlockCnt* bl, lu_byte isloop) {
    bl->isloop = isloop;
    bl->nactvar = fs->nactvar; // 离开 blk 后, fs->nactvar - bl->nactvar 就知道要删除多少局部变量啦
    bl->firstlabel = fs->ls->dyd->label.n; // 本 block 的标签的区段起始位置
    bl->firstgoto = fs->ls->dyd->gt.n; // 本 block 的 goto 标签的区段起始位置
    bl->upval = 0; // 是不是有值被引用
    bl->insidetbc = (fs->bl != NULL && fs->bl->insidetbc);
    bl->previous = fs->bl;
    fs->bl = bl;
    lua_assert(fs->freereg == luaY_nvarstack(fs));
}

/*
** generates an error for an undefined 'goto'.
*/
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
    BlockCnt* bl = fs->bl;
    LexState* ls = fs->ls;
    int hasclose = 0;
    // bl->nactvar 为进入此 block 时, fs 解析出来局部变量的个数
    // block 外部的 block 的寄存使用数量
    int stklevel = reglevel(fs, bl->nactvar); /* level outside the block */
    // 清除 dyd 中缓存的此 block 中的局部变量
    // 把 fs->nactvar 还原成了进入此 block 时的样子
    removevars(fs, bl->nactvar); /* remove block locals */
    lua_assert(bl->nactvar == fs->nactvar); /* back to level on entry */
    if (bl->isloop) /* has to fix pending breaks? */
        // 在循环体最后加上一个 break 的标签
        hasclose = createlabel(ls, luaS_newliteral(ls->L, "break"), 0, 0);
    if (!hasclose && bl->previous && bl->upval) /* still need a 'close'? */
        // 本层被引用的局部变量要进行关闭
        luaK_codeABC(fs, OP_CLOSE, stklevel, 0, 0);
    fs->freereg = stklevel; /* free registers */
    ls->dyd->label.n = bl->firstlabel; /* remove local labels */
    fs->bl = bl->previous; /* current block now is previous one */
    if (bl->previous) /* was it a nested block? */
        movegotosout(fs, bl); /* update pending gotos to enclosing block */
    else {
        if (bl->firstgoto < ls->dyd->gt.n) /* still pending gotos? */
            undefgoto(ls, &ls->dyd->gt.arr[bl->firstgoto]); /* error */
    }
}

/*
** adds a new prototype into list of prototypes
*/
static Proto* addprototype(LexState* ls) {
    Proto* clp;
    lua_State* L = ls->L;
    FuncState* fs = ls->fs; // 这里还是老的 FuncState
    // 这个就是外层函数
    Proto* f = fs->f; /* prototype of current function */
    if (fs->np >= f->sizep) {
        int oldsize = f->sizep;
        luaM_growvector(L, f->p, fs->np, f->sizep, Proto*, MAXARG_Bx, "functions");
        while (oldsize < f->sizep) //
            f->p[oldsize++] = NULL;
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
    ls->fs = fs;
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
    fs->firstlocal = ls->dyd->actvar.n;
    fs->firstlabel = ls->dyd->label.n;
    fs->bl = NULL;
    f->source = ls->source;
    luaC_objbarrier(ls->L, f, f->source);
    f->maxstacksize = 2; /* registers 0/1 are always valid */
    enterblock(fs, bl, 0);
}

static void close_func(LexState* ls) {
    lua_State* L = ls->L;
    FuncState* fs = ls->fs;
    Proto* f = fs->f;
    // 每个函数最后都会加上一个没有返回值的 return 指令
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
        case TK_ELSE:
        case TK_ELSEIF:
        case TK_END:
        case TK_EOS: return 1;
        case TK_UNTIL: return withuntil;
        default: return 0;
    }
}

static void statlist(LexState* ls) {
    /* statlist -> { stat [';'] } */
    while (!block_follow(ls, 1)) {
        if (ls->t.token == TK_RETURN) {
            statement(ls); // 专门用来解析 return 语句的
            return; /* 'return' must be last statement */
        }
        statement(ls);
    }
}

static void fieldsel(LexState* ls, expdesc* v) {
    /* fieldsel -> ['.' | ':'] NAME */
    FuncState* fs = ls->fs;
    expdesc key;
    luaK_exp2anyregup(fs, v); // 确保表在寄存器里, 如果是上值, 那么 luaK_indexed 会处理
    luaX_next(ls); /* skip the dot or colon */
    codename(ls, &key);
    luaK_indexed(fs, v, &key);
}

// 专门给 t[expr] 使用的
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
    expdesc tab, key, val;
    if (ls->t.token == TK_NAME) {
        checklimit(fs, cc->nh, MAX_INT, "items in a constructor");
        codename(ls, &key);
    } else /* ls->t.token == '[' */
        yindex(ls, &key);
    cc->nh++;
    checknext(ls, '=');
    tab = *cc->t;
    luaK_indexed(fs, &tab, &key);
    expr(ls, &val);
    luaK_storevar(fs, &tab, &val);
    fs->freereg = reg; /* free registers */
}

static void closelistfield(FuncState* fs, ConsControl* cc) {
    if (cc->v.k == VVOID) return; /* there is no list item */
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
    ConsControl cc;
    luaK_code(fs, 0); /* space for extra arg. */
    cc.na = cc.nh = cc.tostore = 0;
    cc.t = t;
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
    adjustlocalvars(ls, nparams); // 调整完后 fs->nactvar 就是明确的参数个数
    f->numparams = cast_byte(fs->nactvar);
    if (isvararg) //
        setvararg(fs, f->numparams); /* declared vararg */
    luaK_reserveregs(fs, fs->nactvar); /* reserve registers for parameters */
}

// 函数体解析
static void body(LexState* ls, expdesc* e, int ismethod, int line) {
    /* body ->  '(' parlist ')' block END */
    FuncState new_fs; // 新的 FuncState
    BlockCnt bl; // 新函数对应的 block
    new_fs.f = addprototype(ls); // 给新的 FuncState 加原型
    new_fs.f->linedefined = line;
    open_func(ls, &new_fs, &bl);
    checknext(ls, '(');
    if (ismethod) {
        new_localvarliteral(ls, "self"); /* create 'self' parameter */
        adjustlocalvars(ls, 1);
    }
    parlist(ls);
    checknext(ls, ')');
    statlist(ls);
    new_fs.f->lastlinedefined = ls->linenumber;
    check_match(ls, TK_END, TK_FUNCTION, line);
    // 本层函数解析完毕了, 外层函数要生成创建一个闭包的指令
    codeclosure(ls, e);
    close_func(ls);
}

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
    expdesc args;
    int base, nparams;
    switch (ls->t.token) {
        case '(': { /* funcargs -> '(' [ explist ] ')' */
            luaX_next(ls);
            if (ls->t.token == ')') /* arg list is empty? */
                args.k = VVOID;
            else {
                explist(ls, &args);
                if (hasmultret(args.k)) luaK_setmultret(fs, &args);
            }
            check_match(ls, ')', '(', line);
            break;
        }
        case '{': { /* funcargs -> constructor */
            constructor(ls, &args); //
            break;
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
    base = f->u.info; /* base register for call */
    if (hasmultret(args.k))
        nparams = LUA_MULTRET; /* open call */
    else {
        if (args.k != VVOID) luaK_exp2nextreg(fs, &args); /* close last argument */
        nparams = fs->freereg - (base + 1);
    }
    init_exp(f, VCALL, luaK_codeABC(fs, OP_CALL, base, nparams + 1, 2));
    luaK_fixline(fs, line);
    // 根据函数位置恢复编译时栈状态, 运行时栈状态与此栈相同
    fs->freereg = base + 1; /* call remove function and arguments and leaves
                               (unless changed) one result */
}

/*
** {======================================================================
** Expression parsing
** =======================================================================
*/

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

static void suffixedexp(LexState* ls, expdesc* v) {
    /* suffixedexp ->
         primaryexp { '.' NAME | '[' exp ']' | ':' NAME funcargs | funcargs } */
    FuncState* fs = ls->fs;
    int line = ls->linenumber;
    primaryexp(ls, v);
    for (;;) {
        switch (ls->t.token) {
            case '.': { /* fieldsel */
                fieldsel(ls, v); // 这个比较简单, 后面就是一个字符串
                break;
            }
            case '[': { /* '[' exp ']' */
                expdesc key;
                luaK_exp2anyregup(fs, v);
                yindex(ls, &key); // 解析 key 的内容, key 是一个表达式
                luaK_indexed(fs, v, &key);
                break;
            }
            case ':': { /* ':' NAME funcargs */
                // 必须是一个函数调用
                expdesc key;
                luaX_next(ls);
                codename(ls, &key); // 就是要调用的函数名
                luaK_self(fs, v, &key);
                // 而在 v 指向第一个寄存器, 存放着函数
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

static void simpleexp(LexState* ls, expdesc* v) {
    /* simpleexp -> FLT | INT | STRING | NIL | TRUE | FALSE | ... |
                    constructor | FUNCTION body | suffixedexp */
    switch (ls->t.token) {
        case TK_FLT: {
            init_exp(v, VKFLT, 0);
            v->u.nval = ls->t.seminfo.r;
            break;
        }
        case TK_INT: {
            init_exp(v, VKINT, 0);
            v->u.ival = ls->t.seminfo.i;
            break;
        }
        case TK_STRING: {
            codestring(v, ls->t.seminfo.ts);
            break;
        }
        case TK_NIL: {
            init_exp(v, VNIL, 0);
            break;
        }
        case TK_TRUE: {
            init_exp(v, VTRUE, 0);
            break;
        }
        case TK_FALSE: {
            init_exp(v, VFALSE, 0);
            break;
        }
        case TK_DOTS: { /* vararg */
            FuncState* fs = ls->fs;
            check_condition(ls, fs->f->is_vararg, "cannot use '...' outside a vararg function");
            init_exp(v, VVARARG, luaK_codeABC(fs, OP_VARARG, 0, 0, 1));
            break;
        }
        case '{': { /* constructor */
            constructor(ls, v); //
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

/*
** subexpr -> (simpleexp | unop subexpr) { binop subexpr }
** where 'binop' is any binary operator with a priority higher than 'limit'
*/
static BinOpr subexpr(LexState* ls, expdesc* v, int limit) {
    BinOpr op;
    UnOpr uop;
    enterlevel(ls);
    uop = getunopr(ls->t.token);
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
        BinOpr nextop; // 下一个两元操作符
        int line = ls->linenumber;
        luaX_next(ls); /* skip operator */
        luaK_infix(ls->fs, op, v);
        /* read sub-expression with higher priority */
        nextop = subexpr(ls, &v2, priority[op].right);
        luaK_posfix(ls->fs, op, v, &v2, line);
        op = nextop;
    }
    leavelevel(ls);
    return op; /* return first untreated operator */
}

static void expr(LexState* ls, expdesc* v) { //
    subexpr(ls, v, 0);
}

/* }==================================================================== */

/*
** {======================================================================
** Rules for Statements
** =======================================================================
*/

static void block(LexState* ls) {
    /* block -> statlist */
    FuncState* fs = ls->fs;
    BlockCnt bl;
    enterblock(fs, &bl, 0);
    statlist(ls);
    leaveblock(fs);
}

/*
** structure to chain all variables in the left-hand side of an
** assignment
*/
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
    if (testnext(ls, ',')) { /* restassign -> ',' suffixedexp restassign */
        struct LHS_assign nv;
        nv.prev = lh;
        suffixedexp(ls, &nv.v);
        if (!vkisindexed(nv.v.k)) check_conflict(ls, lh, &nv.v);
        enterlevel(ls); /* control recursion depth */
        restassign(ls, &nv, nvars + 1);
        leavelevel(ls);
    } else { /* restassign -> '=' explist */
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

static int cond(LexState* ls) {
    /* cond -> exp */
    expdesc v;
    expr(ls, &v); /* read condition */
    if (v.k == VNIL) //
        v.k = VFALSE; /* 'falses' are all equal here */
    luaK_goiftrue(ls->fs, &v);
    // 返回当条件是 false 时, 跳转指令列表
    return v.f;
}

static void gotostat(LexState* ls) {
    FuncState* fs = ls->fs;
    int line = ls->linenumber;
    TString* name = str_checkname(ls); /* label's name */
    Labeldesc* lb = findlabel(ls, name);
    if (lb == NULL) /* no label? */
        // 没有已定义的标签, 在 goto 之后定义
        /* forward jump; will be resolved when the label is declared */
        newgotoentry(ls, name, line, luaK_jump(fs));
    else { /* found a label */
        /* backward jump; will be resolved here */
        int lblevel = reglevel(fs, lb->nactvar); /* label level */
        if (luaY_nvarstack(fs) > lblevel) /* leaving the scope of a variable? */
            luaK_codeABC(fs, OP_CLOSE, lblevel, 0, 0);
        /* create jump and link it to the label */
        luaK_patchlist(fs, luaK_jump(fs), lb->pc); // 往回跳
    }
}

/*
** Break statement. Semantically equivalent to "goto break".
*/
static void breakstat(LexState* ls) {
    int line = ls->linenumber;
    luaX_next(ls); /* skip break */
    // break 语句就相当于一个 goto ::break:: 所以在 gt 链上再续上一个
    // 而且, 只有是循环体的 block 会在最后追加一个 break 的标签
    newgotoentry(ls, luaS_newliteral(ls->L, "break"), line, luaK_jump(ls->fs));
}

/*
** Check whether there is already a label with the given 'name'.
*/
static void checkrepeated(LexState* ls, TString* name) {
    Labeldesc* lb = findlabel(ls, name);
    if (l_unlikely(lb != NULL)) { /* already defined? */
        const char* msg = "label '%s' already defined on line %d";
        msg = luaO_pushfstring(ls->L, msg, getstr(name), lb->line);
        luaK_semerror(ls, msg); /* error */
    }
}

static void labelstat(LexState* ls, TString* name, int line) {
    /* label -> '::' NAME '::' */
    // 跳结束的 ::
    checknext(ls, TK_DBCOLON); /* skip double colon */
    while (ls->t.token == ';' || ls->t.token == TK_DBCOLON) //
        statement(ls); /* skip other no-op statements */
    // 就是看看有没有重复定义的标签, 有就报错
    checkrepeated(ls, name); /* check for repeated labels */
    createlabel(ls, name, line, block_follow(ls, 0));
}

static void whilestat(LexState* ls, int line) {
    /* whilestat -> WHILE cond DO block END */
    FuncState* fs = ls->fs;
    int whileinit;
    int condexit; // 条件不满足时, 跳出指令列表
    BlockCnt bl;
    luaX_next(ls); /* skip WHILE */
    whileinit = luaK_getlabel(fs); // while 的回跳地址
    condexit = cond(ls);
    enterblock(fs, &bl, 1);
    checknext(ls, TK_DO);
    block(ls);
    // while 语句的最后一条指令, 是一个条跳转指令, 用于跳回到检测指令
    luaK_jumpto(fs, whileinit); // 跳回 while 再进行条件检测
    check_match(ls, TK_END, TK_WHILE, line);
    leaveblock(fs);
    // while 语句编译完成, 回填测试条件失败后的跳出地址
    luaK_patchtohere(fs, condexit); /* false conditions finish the loop */
}

static void repeatstat(LexState* ls, int line) {
    /* repeatstat -> REPEAT block UNTIL cond */
    int condexit;
    FuncState* fs = ls->fs;
    // repeat 的跳回位置
    int repeat_init = luaK_getlabel(fs);
    BlockCnt bl1, bl2;
    enterblock(fs, &bl1, 1); /* loop block */
    enterblock(fs, &bl2, 0); /* scope block */
    luaX_next(ls); /* skip REPEAT */
    statlist(ls);
    check_match(ls, TK_UNTIL, TK_REPEAT, line);
    // 条件表达式也是 bl2 中
    condexit = cond(ls); /* read condition (inside scope block) */
    leaveblock(fs); /* finish scope */
    // bl2 内部的的 block 在引用 bl2 中的局部变量
    if (bl2.upval) { /* upvalues? */
        // 在最后生成一个跳转指令
        int exit = luaK_jump(fs); /* normal exit must jump over fix */
        // 如果 condexit 条件满足, 那么 condexit 自身的跳转要跳到上面的跳转指令
        luaK_patchtohere(fs, condexit); /* repetition must close upvalues */
        //
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

    if (back) // OP_FORLOOP 在中使用了减法都指令跳转, 所以这里负转为正
        offset = -offset;
    if (l_unlikely(offset > MAXARG_Bx)) //
        luaX_syntaxerror(fs->ls, "control structure too long");
    SETARG_Bx(*jmp, offset);
}

/*
** Generate code for a 'for' loop.
*/
static void forbody(LexState* ls, int base, int line, int nvars, int isgen) {
    /* forbody -> DO block */
    // 使用 isgen 来判断是不是需要使用迭代器, 0 为不需要, 1 为需要
    static const OpCode forprep[2] = {OP_FORPREP, OP_TFORPREP};
    static const OpCode forloop[2] = {OP_FORLOOP, OP_TFORLOOP};
    BlockCnt bl;
    FuncState* fs = ls->fs;
    int prep, endfor;
    checknext(ls, TK_DO);
    // 返回的是 forprep[isgen] 指令的索引
    prep = luaK_codeABx(fs, forprep[isgen], base, 0);
    enterblock(fs, &bl, 0); /* scope for declared variables */
    adjustlocalvars(ls, nvars);
    // 生成临时变量, 用于计数器的复本
    luaK_reserveregs(fs, nvars);
    block(ls);
    leaveblock(fs); /* end of scope for declared variables */
    // 回填 forprep 的跳转地址
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
    int base = fs->freereg; // 初始值所在的寄存器
    // 生成三个临时的局部变量, 用来存初始值, 限制与步长
    new_localvarliteral(ls, "(for state)");
    new_localvarliteral(ls, "(for state)");
    new_localvarliteral(ls, "(for state)");
    new_localvar(ls, varname); // 计数器
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
    int base = fs->freereg; // 第一个 (for state)
    /* create control variables */
    new_localvarliteral(ls, "(for state)"); // 这 4 个就是 in 后面用的
    new_localvarliteral(ls, "(for state)");
    new_localvarliteral(ls, "(for state)");
    new_localvarliteral(ls, "(for state)");
    /* create declared variables */
    new_localvar(ls, indexname); // for 的第一个变量, 在这里就是存 key 值的
    while (testnext(ls, ',')) {
        new_localvar(ls, str_checkname(ls));
        nvars++;
    }
    checknext(ls, TK_IN);
    line = ls->linenumber;
    // 有 4 个局部变量(for state) 要被赋值, explist(ls, &e) 返回表达式的个数, e 是表达式列表的最后一项
    adjust_assign(ls, 4, explist(ls, &e), &e);
    adjustlocalvars(ls, 4); /* control variables */
    // 这里很有意思, 最后一个 (for state) 如果不是 nil(false) 放那么就要是 <close>
    marktobeclosed(fs); /* last control var. must be closed */
    // 这里又看了一个是不是有 3 个多余的栈, 因为一会在循环里要用
    luaK_checkstack(fs, 3); /* extra space to call generator */
    // nvars - 4 就是 in 前面参数的个数
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
    BlockCnt bl;
    FuncState* fs = ls->fs;
    expdesc v;
    int jf; /* instruction to skip 'then' code (if condition is false) */
    luaX_next(ls); /* skip IF or ELSEIF */
    expr(ls, &v); /* read condition */
    checknext(ls, TK_THEN);
    if (ls->t.token == TK_BREAK) { /* 'if x then break' ? */
        int line = ls->linenumber;
        luaK_goiffalse(ls->fs, &v); /* will jump if condition is true */
        luaX_next(ls); /* skip 'break' */
        enterblock(fs, &bl, 0); /* must enter block before 'goto' */
        newgotoentry(ls, luaS_newliteral(ls->L, "break"), line, v.t);
        while (testnext(ls, ';')) {} /* skip semicolons */
        if (block_follow(ls, 0)) { /* jump is the entire block? */
            leaveblock(fs); // 离开外部循环
            return; /* and that is it */
        } else /* must skip over 'then' part if condition is false */
            jf = luaK_jump(fs);
    } else { /* regular case (not a break) */
        luaK_goiftrue(ls->fs, &v); /* skip over block if condition is false */
        enterblock(fs, &bl, 0);
        jf = v.f; // 当 v 为 false 时跳转地址
    }
    statlist(ls); /* 'then' part */
    leaveblock(fs);
    if (ls->t.token == TK_ELSE || ls->t.token == TK_ELSEIF) /* followed by 'else'/'elseif'? */
        // 这里生成不带测试指令的跳转指令, 用于在 then 后面的代码执行后, 跳过后面的 else 与 elseif 的代码块
        luaK_concat(fs, escapelist, luaK_jump(fs)); /* must jump over it */
    // then 后面的代码块编译完成, 已经可以确定跳转的目标地址了, 所以回填跳转的目标地址
    luaK_patchtohere(fs, jf);
}

static void ifstat(LexState* ls, int line) {
    /* ifstat -> IF cond THEN block {ELSEIF cond THEN block} [ELSE block] END */
    FuncState* fs = ls->fs;
    int escapelist = NO_JUMP; /* exit list for finished parts */
    test_then_block(ls, &escapelist); /* IF cond THEN block */
    while (ls->t.token == TK_ELSEIF) //
        test_then_block(ls, &escapelist); /* ELSEIF cond THEN block */
    if (testnext(ls, TK_ELSE)) //
        block(ls); /* 'else' part */
    check_match(ls, TK_END, TK_IF, line);
    // if 语句已经解析完毕, 可以回填 if 的各个分支的逃离跳转指令了
    luaK_patchtohere(fs, escapelist); /* patch escape list to 'if' end */
}

static void localfunc(LexState* ls) {
    expdesc b;
    FuncState* fs = ls->fs;
    int fvar = fs->nactvar; /* function's variable index */
    new_localvar(ls, str_checkname(ls)); /* new local variable */
    adjustlocalvars(ls, 1); /* enter its scope */
    body(ls, &b, 0, ls->linenumber); /* function created in next register */
    /* debug information will only see the variable after this point! */
    localdebuginfo(fs, fvar)->startpc = fs->pc;
}

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

static void checktoclose(FuncState* fs, int level) {
    if (level != -1) { /* is there a to-be-closed variable? */
        marktobeclosed(fs);
        // 从是第几个局部变量来找到寄存器的位置, 因为真编译时常量真不在寄存器里
        luaK_codeABC(fs, OP_TBC, reglevel(fs, level), 0, 0);
    }
}

static void localstat(LexState* ls) {
    /* stat -> LOCAL NAME ATTRIB { ',' NAME ATTRIB } ['=' explist] */
    FuncState* fs = ls->fs;
    int toclose = -1; /* index of to-be-closed variable (if any) */
    Vardesc* var; /* last variable */
    int vidx, kind; /* index and kind of last variable */
    int nvars = 0;
    int nexps;
    expdesc e; // 接收表达式的结果
    do {
        vidx = new_localvar(ls, str_checkname(ls));
        kind = getlocalattribute(ls);
        getlocalvardesc(fs, vidx)->vd.kind = kind;
        if (kind == RDKTOCLOSE) { /* to-be-closed? */
            // 一条 local 语句只能定义一个 <close>
            if (toclose != -1) /* one already present? */
                luaK_semerror(ls, "multiple to-be-closed variables in local list");
            toclose = fs->nactvar + nvars; // 说明这个 <close> 是 fs 的第几个局部变量
        }
        nvars++;
    } while (testnext(ls, ','));
    if (testnext(ls, '='))
        nexps = explist(ls, &e);
    else {
        e.k = VVOID;
        nexps = 0;
    }
    var = getlocalvardesc(fs, vidx); /* get last variable */
    if (nvars == nexps && /* no adjustments? */
        var->vd.kind == RDKCONST && /* last variable is const? */
        // 这里会尝试把变量变量运行时常量, 如果不行就是普通常量, 在赋值语句中检查写权限
        luaK_exp2const(fs, &e, &var->k)) { /* compile-time constant? */
        var->vd.kind = RDKCTC; /* variable is a compile-time constant */
        adjustlocalvars(ls, nvars - 1); /* exclude last variable */
        fs->nactvar++; /* but count it */
    } else {
        adjust_assign(ls, nvars, nexps, &e);
        adjustlocalvars(ls, nvars);
    }
    checktoclose(fs, toclose);
}

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
    // 使用 function A:a() 定义的 ismethod 就为 true
    ismethod = funcname(ls, &v);
    body(ls, &b, ismethod, line);
    check_readonly(ls, &v);
    // b 表示一个生成闭包的指令, 这里是把生成的闭包放那到哪里去
    luaK_storevar(ls->fs, &v, &b);
    luaK_fixline(ls->fs, line); /* definition "happens" in the first line */
}

static void exprstat(LexState* ls) {
    /* stat -> func | assignment */
    FuncState* fs = ls->fs;
    struct LHS_assign v;
    suffixedexp(ls, &v.v);
    if (ls->t.token == '=' || ls->t.token == ',') { /* stat -> assignment ? */
        v.prev = NULL;
        restassign(ls, &v, 1);
    } else { /* stat -> func */
        Instruction* inst;
        check_condition(ls, v.v.k == VCALL, "syntax error");
        inst = &getinstruction(fs, &v.v);
        SETARG_C(*inst, 1); /* call statement uses no results */
    }
}

static void retstat(LexState* ls) {
    /* stat -> RETURN [explist] [';'] */
    FuncState* fs = ls->fs;
    expdesc e;
    int nret; /* number of values being returned */
    // 做当前最后的局部变量的寄存器位置, 在这里就是下一个可用的寄存器
    int first = luaY_nvarstack(fs); /* first slot to be returned */
    if (block_follow(ls, 1) || ls->t.token == ';')
        // 说明 return 后面就是或是 [;] block_follow, 所以就是没有返回值
        nret = 0; /* return no values */
    else {
        // 这里解析一个 explist, 值的位置从 first 往上摞
        nret = explist(ls, &e); /* optional return values */
        if (hasmultret(e.k)) {
            luaK_setmultret(fs, &e);
            if (e.k == VCALL && nret == 1 && !fs->bl->insidetbc) { /* tail call? */
                SET_OPCODE(getinstruction(fs, &e), OP_TAILCALL);
                lua_assert(GETARG_A(getinstruction(fs, &e)) == luaY_nvarstack(fs));
            }
            nret = LUA_MULTRET; /* return all values */
        } else {
            // 返回值多少可以确定
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
        case ';': { /* stat -> ';' (empty statement) */
            luaX_next(ls); /* skip ';' */
            break;
        }
        case TK_IF: { /* stat -> ifstat */
            ifstat(ls, line); //
            break;
        }
        case TK_WHILE: { /* stat -> whilestat */
            whilestat(ls, line); //
            break;
        }
        case TK_DO: { /* stat -> DO block END */
            luaX_next(ls); /* skip DO */
            block(ls);
            check_match(ls, TK_END, TK_DO, line);
            break;
        }
        case TK_FOR: { /* stat -> forstat */
            forstat(ls, line); //
            break;
        }
        case TK_REPEAT: { /* stat -> repeatstat */
            repeatstat(ls, line); //
            break;
        }
        case TK_FUNCTION: { /* stat -> funcstat */
            funcstat(ls, line); //
            break;
        }
        case TK_LOCAL: { /* stat -> localstat */
            luaX_next(ls); /* skip LOCAL */
            if (testnext(ls, TK_FUNCTION)) /* local function? */
                localfunc(ls);
            else
                localstat(ls);
            break;
        }
        case TK_DBCOLON: { /* stat -> label */
            luaX_next(ls); /* skip double colon */
            labelstat(ls, str_checkname(ls), line);
            break;
        }
        case TK_RETURN: { /* stat -> retstat */
            luaX_next(ls); /* skip RETURN */
            retstat(ls);
            break;
        }
        case TK_BREAK: { /* stat -> breakstat */
            breakstat(ls); //
            break;
        }
        case TK_GOTO: { /* stat -> 'goto' NAME */
            luaX_next(ls); /* skip 'goto' */
            gotostat(ls);
            break;
        }
        default: { /* stat -> func | assignment */
            exprstat(ls); //
            break;
        }
    }
    lua_assert(ls->fs->f->maxstacksize >= ls->fs->freereg && ls->fs->freereg >= luaY_nvarstack(ls->fs));
    ls->fs->freereg = luaY_nvarstack(ls->fs); /* free registers */
    leavelevel(ls);
}

/* }====================================================================== */

/*
** compiles the main function, which is a regular vararg function with an
** upvalue named LUA_ENV
*/
static void mainfunc(LexState* ls, FuncState* fs) {
    BlockCnt bl;
    Upvaldesc* env;
    open_func(ls, fs, &bl);
    setvararg(fs, 0); /* main function is always declared vararg */
    env = allocupvalue(fs); /* ...set environment upvalue */
    env->instack = 1;
    env->idx = 0;
    env->kind = VDKREG;
    env->name = ls->envn;
    luaC_objbarrier(ls->L, fs->f, env->name);
    luaX_next(ls); /* read first token */
    statlist(ls); /* parse main body */
    check(ls, TK_EOS);
    close_func(ls);
}

LClosure* luaY_parser(lua_State* L, ZIO* z, Mbuffer* buff, Dyndata* dyd, const char* name, int firstchar) {
    LexState lexstate;
    FuncState funcstate;
    LClosure* cl = luaF_newLclosure(L, 1); /* create main closure */
    setclLvalue2s(L, L->top.p, cl); /* anchor it (to avoid being collected) */
    luaD_inctop(L);
    lexstate.h = luaH_new(L); /* create table for scanner */
    sethvalue2s(L, L->top.p, lexstate.h); /* anchor it */
    luaD_inctop(L);
    funcstate.f = cl->p = luaF_newproto(L);
    luaC_objbarrier(L, cl, cl->p);
    funcstate.f->source = luaS_new(L, name); /* create and anchor TString */
    luaC_objbarrier(L, funcstate.f, funcstate.f->source);
    lexstate.buff = buff;
    lexstate.dyd = dyd;
    dyd->actvar.n = dyd->gt.n = dyd->label.n = 0;
    luaX_setinput(L, &lexstate, z, funcstate.f->source, firstchar);
    mainfunc(&lexstate, &funcstate);
    lua_assert(!funcstate.prev && funcstate.nups == 1 && !lexstate.fs);
    /* all scopes should be correctly finished */
    lua_assert(dyd->actvar.n == 0 && dyd->gt.n == 0 && dyd->label.n == 0);
    L->top.p--; /* remove scanner's table */
    return cl; /* closure is on the stack, too */
}
