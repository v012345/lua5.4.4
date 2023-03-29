/*
** $Id: lstate.c $
** Global State
** See Copyright Notice in lua.h
** 全局状态机!
*/

#define lstate_c
#define LUA_CORE

#include "lprefix.h"

#include <stddef.h>
#include <string.h>

#include "lua.h"

#include "lapi.h"
#include "ldebug.h"
#include "ldo.h"
#include "lfunc.h"
#include "lgc.h"
#include "llex.h"
#include "lmem.h"
#include "lstate.h"
#include "lstring.h"
#include "ltable.h"
#include "ltm.h"

/*
** thread state + extra space
*/
typedef struct LX {
    lu_byte extra_[LUA_EXTRASPACE];
    lua_State l;
} LX;

/**
 * @brief Main thread combines a thread state and the global state 为了避免内存碎片, 减少内存分配与释放的次数, 所以把 全局状态机 与 主线程状态放到了一个结构体中
 */
typedef struct LG {
    LX l;
    global_State g;
} LG;

#define fromstate(L) (cast(LX*, cast(lu_byte*, (L)) - offsetof(LX, l)))

/*
** A macro to create a "random" seed when a state is created;
** the seed is used to randomize string hashes.
*/
#if !defined(luai_makeseed)

#include <time.h>

/*
** Compute an initial seed with some level of randomness.
** Rely on Address Space Layout Randomization (if present) and
** current time.
*/
#define addbuff(b, p, e)                                                                                                                                                                               \
    {                                                                                                                                                                                                  \
        size_t t = cast_sizet(e);                                                                                                                                                                      \
        memcpy(b + p, &t, sizeof(t));                                                                                                                                                                  \
        p += sizeof(t);                                                                                                                                                                                \
    }

/**
 * @brief 利用时间 与 内存地址随机性 生成一个随机数种子
 *
 * @param L
 * @return unsigned int
 */
static unsigned int luai_makeseed(lua_State* L) {
    char buff[3 * sizeof(size_t)];
    unsigned int h = cast_uint(time(NULL));
    int p = 0;
    addbuff(buff, p, L); /* heap variable */
    addbuff(buff, p, &h); /* local variable */
    addbuff(buff, p, &lua_newstate); /* public function */
    lua_assert(p == sizeof(buff));
    // 求出随机生成的 buff 字符串 相对于 当前时间的 hash, 一个 unsigned int 值, 来作为全局状态机的随机数种子
    return luaS_hash(buff, p, h);
}

#endif

/*
** set GCdebt to a new value keeping the value (totalbytes + GCdebt)
** invariant (and avoiding underflows in 'totalbytes')
*/
void luaE_setdebt(global_State* g, l_mem debt) {
    l_mem tb = gettotalbytes(g);
    lua_assert(tb > 0);
    if (debt < tb - MAX_LMEM) debt = tb - MAX_LMEM; /* will make 'totalbytes == MAX_LMEM' */
    g->totalbytes = tb - debt;
    g->GCdebt = debt;
}

LUA_API int lua_setcstacklimit(lua_State* L, unsigned int limit) {
    UNUSED(L);
    UNUSED(limit);
    return LUAI_MAXCCALLS; /* warning?? */
}

/**
 * @brief 创建一个新的调用信息(CallInfo)对象,并将其插入到 L->ci 后面
 *
 * @param L
 * @return CallInfo*
 */
CallInfo* luaE_extendCI(lua_State* L) {
    CallInfo* ci;
    lua_assert(L->ci->next == NULL);
    ci = luaM_new(L, CallInfo);
    lua_assert(L->ci->next == NULL);
    L->ci->next = ci;
    ci->previous = L->ci;
    ci->next = NULL;
    ci->u.l.trap = 0;
    L->nci++;
    return ci;
}

/*
** free all CallInfo structures not in use by a thread
*/
void luaE_freeCI(lua_State* L) {
    CallInfo* ci = L->ci;
    CallInfo* next = ci->next;
    ci->next = NULL;
    while ((ci = next) != NULL) {
        next = ci->next;
        luaM_free(L, ci);
        L->nci--;
    }
}

/*
** free half of the CallInfo structures not in use by a thread,
** keeping the first one.
*/
void luaE_shrinkCI(lua_State* L) {
    CallInfo* ci = L->ci->next; /* first free CallInfo */
    CallInfo* next;
    if (ci == NULL) return; /* no extra elements */
    while ((next = ci->next) != NULL) { /* two extra elements? */
        CallInfo* next2 = next->next; /* next's next */
        ci->next = next2; /* remove next from the list */
        L->nci--;
        luaM_free(L, next); /* free next */
        if (next2 == NULL)
            break; /* no more elements */
        else {
            next2->previous = ci;
            ci = next2; /* continue */
        }
    }
}

/*
** Called when 'getCcalls(L)' larger or equal to LUAI_MAXCCALLS.
** If equal, raises an overflow error. If value is larger than
** LUAI_MAXCCALLS (which means it is handling an overflow) but
** not much larger, does not report an error (to allow overflow
** handling to work).
*/
void luaE_checkcstack(lua_State* L) {
    if (getCcalls(L) == LUAI_MAXCCALLS)
        luaG_runerror(L, "C stack overflow");
    else if (getCcalls(L) >= (LUAI_MAXCCALLS / 10 * 11))
        luaD_throw(L, LUA_ERRERR); /* error while handling stack error */
}

LUAI_FUNC void luaE_incCstack(lua_State* L) {
    L->nCcalls++;
    if (l_unlikely(getCcalls(L) >= LUAI_MAXCCALLS)) luaE_checkcstack(L);
}

static void stack_init(lua_State* L1, lua_State* L) {
    int i;
    CallInfo* ci;
    /* initialize stack array */
    L1->stack = luaM_newvector(L, BASIC_STACK_SIZE + EXTRA_STACK, StackValue); // 分配数据栈 基础大小加上额外的空间
    L1->tbclist = L1->stack; // 待关闭的列表也指向栈底
    for (i = 0; i < BASIC_STACK_SIZE + EXTRA_STACK; i++) setnilvalue(s2v(L1->stack + i)); /* 初始化分配来的栈 erase new stack */
    L1->top = L1->stack; // top指向最后一个空闲的位置, 现在栈底就是最后一个空闲的位置
    L1->stack_last = L1->stack + BASIC_STACK_SIZE; // stack_last指向数据栈的基础部分的栈尾
    /* initialize first ci */
    ci = &L1->base_ci; // 初始化 L1->base_ci, L1->base_ci 记录的是整个Lua栈的状态
    ci->next = ci->previous = NULL; // 没有前驱与后续
    ci->callstatus = CIST_C; // base_ci 用来调用一个 c 函数
    ci->func = L1->top; // 将func指针指向栈顶,因为这个CallInfo记录的是整个Lua栈的状态,而不仅仅是当前函数调用的状态
    ci->u.c.k = NULL;
    ci->nresults = 0;
    setnilvalue(s2v(L1->top)); /* 'function' entry for this 'ci' */
    L1->top++;
    ci->top = L1->top + LUA_MINSTACK; // ci->top 指向 ci->base 上面的第 20 个元素
    L1->ci = ci; // 将ci设置为当前lua_State的ci字段,表示这是当前正在执行的函数调用信息
}

static void freestack(lua_State* L) {
    if (L->stack == NULL) return; /* stack not completely built yet */
    L->ci = &L->base_ci; /* free the entire 'ci' list */
    luaE_freeCI(L);
    lua_assert(L->nci == 0);
    luaM_freearray(L, L->stack, stacksize(L) + EXTRA_STACK); /* free stack */
}

/*
** Create registry table and its predefined values
*/
static void init_registry(lua_State* L, global_State* g) {
    /* create registry */
    Table* registry = luaH_new(L);
    sethvalue(L, &g->l_registry, registry);
    luaH_resize(L, registry, LUA_RIDX_LAST, 0);
    /* registry[LUA_RIDX_MAINTHREAD] = L */
    setthvalue(L, &registry->array[LUA_RIDX_MAINTHREAD - 1], L);
    /* registry[LUA_RIDX_GLOBALS] = new table (table of globals) */
    sethvalue(L, &registry->array[LUA_RIDX_GLOBALS - 1], luaH_new(L));
}

// 进行一些要用栈 和 串 的初始化; open parts of the state that may cause memory-allocation errors.
static void f_luaopen(lua_State* L, void* ud) {
    global_State* g = G(L);
    UNUSED(ud);
    stack_init(L, L); /* init stack */
    init_registry(L, g); // 初始化 l_registry
    luaS_init(L); // 给出一个基本的字符串池
    luaT_init(L); // 初始化元表的字符串
    luaX_init(L); // 初始化词法分析用的token串
    g->gcstp = 0; /* allow gc */
    setnilvalue(&g->nilvalue); /* now state is complete */
    luai_userstateopen(L); // 宏定义的接口, 用户去实现
}

/// @brief 就是简单初始化 不分配内存空间, 但是 L->l_G = g; preinitialize a thread with consistent values without allocating any memory (to avoid errors)
static void preinit_thread(lua_State* L, global_State* g) {
    G(L) = g;
    L->stack = NULL;
    L->ci = NULL;
    L->nci = 0;
    L->twups = L; /* thread has no upvalues */
    L->nCcalls = 0;
    L->errorJmp = NULL;
    L->hook = NULL;
    L->hookmask = 0;
    L->basehookcount = 0;
    L->allowhook = 1;
    resethookcount(L); // L->hookcount = L->basehookcount
    L->openupval = NULL;
    L->status = LUA_OK;
    L->errfunc = 0;
    L->oldpc = 0;
}

static void close_state(lua_State* L) {
    global_State* g = G(L);
    if (!completestate(g)) /* closing a partially built state? */
        luaC_freeallobjects(L); /* just collect its objects */
    else { /* closing a fully built state */
        L->ci = &L->base_ci; /* unwind CallInfo list */
        luaD_closeprotected(L, 1, LUA_OK); /* close all upvalues */
        luaC_freeallobjects(L); /* collect all objects */
        luai_userstateclose(L);
    }
    luaM_freearray(L, G(L)->strt.hash, G(L)->strt.size);
    freestack(L);
    lua_assert(gettotalbytes(g) == sizeof(LG));
    // 这里要求 LG 结构体中 LX (主线程) 必须定义在结构的前面, 否则关闭虚拟机的时候就无法正确的释放内存
    (*g->frealloc)(g->ud, fromstate(L), sizeof(LG), 0); /* free main block */
}

LUA_API lua_State* lua_newthread(lua_State* L) {
    global_State* g;
    lua_State* L1;
    lua_lock(L);
    g = G(L);
    luaC_checkGC(L);
    /* create new thread */
    L1 = &cast(LX*, luaM_newobject(L, LUA_TTHREAD, sizeof(LX)))->l;
    L1->marked = luaC_white(g);
    L1->tt = LUA_VTHREAD;
    /* link it on list 'allgc' */
    L1->next = g->allgc;
    g->allgc = obj2gco(L1);
    /* anchor it on L stack */
    setthvalue2s(L, L->top, L1);
    api_incr_top(L);
    preinit_thread(L1, g);
    L1->hookmask = L->hookmask;
    L1->basehookcount = L->basehookcount;
    L1->hook = L->hook;
    resethookcount(L1);
    /* initialize L1 extra space */
    memcpy(lua_getextraspace(L1), lua_getextraspace(g->mainthread), LUA_EXTRASPACE);
    luai_userstatethread(L, L1);
    stack_init(L1, L); /* init stack */
    lua_unlock(L);
    return L1;
}

void luaE_freethread(lua_State* L, lua_State* L1) {
    LX* l = fromstate(L1);
    luaF_closeupval(L1, L1->stack); /* close all upvalues */
    lua_assert(L1->openupval == NULL);
    luai_userstatefree(L, L1);
    freestack(L1);
    luaM_free(L, l);
}

int luaE_resetthread(lua_State* L, int status) {
    CallInfo* ci = L->ci = &L->base_ci; /* unwind CallInfo list */
    setnilvalue(s2v(L->stack)); /* 'function' entry for basic 'ci' */
    ci->func = L->stack;
    ci->callstatus = CIST_C;
    if (status == LUA_YIELD) status = LUA_OK;
    L->status = LUA_OK; /* so it can run __close metamethods */
    status = luaD_closeprotected(L, 1, status);
    if (status != LUA_OK) /* errors? */
        luaD_seterrorobj(L, status, L->stack + 1);
    else
        L->top = L->stack + 1;
    ci->top = L->top + LUA_MINSTACK;
    luaD_reallocstack(L, cast_int(ci->top - L->stack), 0);
    return status;
}

LUA_API int lua_resetthread(lua_State* L) {
    int status;
    lua_lock(L);
    status = luaE_resetthread(L, L->status);
    lua_unlock(L);
    return status;
}

LUA_API lua_State* lua_newstate(lua_Alloc f, void* ud) {
    int i;
    lua_State* L;
    global_State* g;
    /* 把 lua_Alloc f 返回的内存空间的 void* 强转为 LG* */
    LG* l = cast(LG*, (*f)(ud, NULL, LUA_TTHREAD, sizeof(LG)));
    if (l == NULL) return NULL;
    L = &l->l.l;
    g = &l->g;
    L->tt = LUA_VTHREAD;
    g->currentwhite = bitmask(WHITE0BIT); // 白 0 阶段
    L->marked = luaC_white(g); // 与 g->currentwhite 的 3 与 4 位置一样
    preinit_thread(L, g);
    g->allgc = obj2gco(L); /* 把主线程的 GCObject 入到链头; by now, only object is the main thread */
    L->next = NULL;
    incnny(L); /* 把 nCcalls 的第 17 位置 1; main thread is always non yieldable */
    g->frealloc = f;
    g->ud = ud;
    g->warnf = NULL;
    g->ud_warn = NULL;
    g->mainthread = L;
    g->seed = luai_makeseed(L); // 启动时生成的一个随机数种子, 主要是在求字符串哈希时使用
    g->gcstp = GCSTPGC; /* 初始化 state 时不进行 GC; no GC while building state */
    g->strt.size = g->strt.nuse = 0;
    g->strt.hash = NULL;
    setnilvalue(&g->l_registry);
    g->panic = NULL;
    g->gcstate = GCSpause;
    g->gckind = KGC_INC;
    g->gcstopem = 0;
    g->gcemergency = 0;
    g->finobj = g->tobefnz = g->fixedgc = NULL;
    g->firstold1 = g->survival = g->old1 = g->reallyold = NULL;
    g->finobjsur = g->finobjold1 = g->finobjrold = NULL;
    g->sweepgc = NULL;
    g->gray = g->grayagain = NULL;
    g->weak = g->ephemeron = g->allweak = NULL;
    g->twups = NULL;
    g->totalbytes = sizeof(LG);
    g->GCdebt = 0;
    g->lastatomic = 0;
    setivalue(&g->nilvalue, 0); /* to signal that state is not yet built */
    setgcparam(g->gcpause, LUAI_GCPAUSE);
    setgcparam(g->gcstepmul, LUAI_GCMUL);
    g->gcstepsize = LUAI_GCSTEPSIZE;
    setgcparam(g->genmajormul, LUAI_GENMAJORMUL);
    g->genminormul = LUAI_GENMINORMUL;
    for (i = 0; i < LUA_NUMTAGS; i++) g->mt[i] = NULL;
    // 初始化了一些 栈与串
    if (luaD_rawrunprotected(L, f_luaopen, NULL) != LUA_OK) {
        /* memory allocation error: free partial state */
        close_state(L);
        L = NULL;
    }
    return L;
}

LUA_API void lua_close(lua_State* L) {
    lua_lock(L);
    L = G(L)->mainthread; /* only the main thread can be closed */
    close_state(L);
}

void luaE_warning(lua_State* L, const char* msg, int tocont) {
    lua_WarnFunction wf = G(L)->warnf;
    if (wf != NULL) wf(G(L)->ud_warn, msg, tocont);
}

/*
** Generate a warning from an error message
*/
void luaE_warnerror(lua_State* L, const char* where) {
    TValue* errobj = s2v(L->top - 1); /* error object */
    const char* msg = (ttisstring(errobj)) ? svalue(errobj) : "error object is not a string";
    /* produce warning "error in %s (%s)" (where, msg) */
    luaE_warning(L, "error in ", 1);
    luaE_warning(L, where, 1);
    luaE_warning(L, " (", 1);
    luaE_warning(L, msg, 1);
    luaE_warning(L, ")", 0);
}
