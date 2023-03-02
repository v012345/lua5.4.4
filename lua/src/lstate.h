/*
** $Id: lstate.h $
** Global State
** See Copyright Notice in lua.h
*/

#ifndef lstate_h
#define lstate_h

#include "lua.h"

#include "lobject.h"
#include "ltm.h"
#include "lzio.h"


/*
** Some notes about garbage-collected objects: All objects in Lua must
** be kept somehow accessible until being freed, so all objects always
** belong to one (and only one) of these lists, using field 'next' of
** the 'CommonHeader' for the link:
**
** 'allgc': all objects not marked for finalization;
** 'finobj': all objects marked for finalization;
** 'tobefnz': all objects ready to be finalized;
** 'fixedgc': all objects that are not to be collected (currently
** only small strings, such as reserved words).
**
** For the generational collector, some of these lists have marks for
** generations. Each mark points to the first element in the list for
** that particular generation; that generation goes until the next mark.
**
** 'allgc' -> 'survival': new objects;
** 'survival' -> 'old': objects that survived one collection;
** 'old1' -> 'reallyold': objects that became old in last collection;
** 'reallyold' -> NULL: objects old for more than one cycle.
**
** 'finobj' -> 'finobjsur': new objects marked for finalization;
** 'finobjsur' -> 'finobjold1': survived   """";
** 'finobjold1' -> 'finobjrold': just old  """";
** 'finobjrold' -> NULL: really old       """".
**
** All lists can contain elements older than their main ages, due
** to 'luaC_checkfinalizer' and 'udata2finalize', which move
** objects between the normal lists and the "marked for finalization"
** lists. Moreover, barriers can age young objects in young lists as
** OLD0, which then become OLD1. However, a list never contains
** elements younger than their main ages.
**
** The generational collector also uses a pointer 'firstold1', which
** points to the first OLD1 object in the list. It is used to optimize
** 'markold'. (Potentially OLD1 objects can be anywhere between 'allgc'
** and 'reallyold', but often the list has no OLD1 objects or they are
** after 'old1'.) Note the difference between it and 'old1':
** 'firstold1': no OLD1 objects before this point; there can be all
**   ages after it.
** 'old1': no objects younger than OLD1 after this point.
*/

/*
** Moreover, there is another set of lists that control gray objects.
** These lists are linked by fields 'gclist'. (All objects that
** can become gray have such a field. The field is not the same
** in all objects, but it always has this name.)  Any gray object
** must belong to one of these lists, and all objects in these lists
** must be gray (with two exceptions explained below):
**
** 'gray': regular gray objects, still waiting to be visited.
** 'grayagain': objects that must be revisited at the atomic phase.
**   That includes
**   - black objects got in a write barrier;
**   - all kinds of weak tables during propagation phase;
**   - all threads.
** 'weak': tables with weak values to be cleared;
** 'ephemeron': ephemeron tables with white->white entries;
** 'allweak': tables with weak keys and/or weak values to be cleared.
**
** The exceptions to that "gray rule" are:
** - TOUCHED2 objects in generational mode stay in a gray list (because
** they must be visited again at the end of the cycle), but they are
** marked black because assignments to them must activate barriers (to
** move them back to TOUCHED1).
** - Open upvales are kept gray to avoid barriers, but they stay out
** of gray lists. (They don't even have a 'gclist' field.)
*/



/*
** About 'nCcalls':  This count has two parts: the lower 16 bits counts
** the number of recursive invocations in the C stack; the higher
** 16 bits counts the number of non-yieldable calls in the stack.
** (They are together so that we can change and save both with one
** instruction.)
*/


/* true if this thread does not have non-yieldable calls in the stack */
#define yieldable(L)		(((L)->nCcalls & 0xffff0000) == 0)

/* real number of C calls */
#define getCcalls(L)	((L)->nCcalls & 0xffff)


/* Increment the number of non-yieldable calls */
#define incnny(L)	((L)->nCcalls += 0x10000)

/* Decrement the number of non-yieldable calls */
#define decnny(L)	((L)->nCcalls -= 0x10000)

/* Non-yieldable call increment */
#define nyci	(0x10000 | 1)




struct lua_longjmp;  /* defined in ldo.c */


/*
** Atomic type (relative to signals) to better ensure that 'lua_sethook'
** is thread safe
*/
#if !defined(l_signalT)
#include <signal.h>
#define l_signalT	sig_atomic_t
#endif


/*
** Extra stack space to handle TM calls and some other extras. This
** space is not included in 'stack_last'. It is used only to avoid stack
** checks, either because the element will be promptly popped or because
** there will be a stack check soon after the push. Function frames
** never use this extra space, so it does not need to be kept clean.
*/
#define EXTRA_STACK   5


#define BASIC_STACK_SIZE        (2*LUA_MINSTACK)

#define stacksize(th)	cast_int((th)->stack_last - (th)->stack)


/* kinds of Garbage Collection */
#define KGC_INC		0	/* incremental gc */
#define KGC_GEN		1	/* generational gc */


/**
 * @brief 字符串的哈希表 , 有大小 , 元素的个数 , 与一个 TString 的二维组数(一个哈希桶)
 */
typedef struct stringtable {
  TString **hash; //字符串的哈希表的哈希桶
  int nuse;  /* 表中已存储的短串的数量  number of elements */
  int size; // 哈希桶的大小 , 就是预定容量, luaS_init 时给出 初始化大小 MINSTRTABSIZE ( 2^7 = 128 ), 之后可以调整大小 , 注意 size 是 2 的幂次
} stringtable;


/*
** Information about a call.
** About union 'u':
** - field 'l' is used only for Lua functions;
** - field 'c' is used only for C functions.
** About union 'u2':
** - field 'funcidx' is used only by C functions while doing a
** protected call;
** - field 'nyield' is used only while a function is "doing" an
** yield (from the yield until the next resume);
** - field 'nres' is used only while closing tbc variables when
** returning from a function;
** - field 'transferinfo' is used only during call/returnhooks,
** before the function starts or after it ends.
*/
typedef struct CallInfo {
  StkId func;  /* 当前调用的函数在栈中的位置 function index in the stack */
  StkId	top;  /* 当前栈顶位置，指向当前函数栈帧的栈顶位置 top for this function */
  struct CallInfo *previous, *next;  /* CallInfo 对象的双向链表，用于维护调用栈 dynamic call link */
  union { // 联合体，用于保存不同类型函数的信
    struct {  /* only for Lua functions */
      const Instruction *savedpc;
      volatile l_signalT trap;
      int nextraargs;  /* # of extra arguments in vararg functions */
    } l; // 只对 Lua 函数有效，保存了当前 Lua 函数执行的一些信息，比如指令指针、附加的参数个数、当前状态的 trap 等
    struct {  /* only for C functions */
      lua_KFunction k;  /* continuation in case of yields */
      ptrdiff_t old_errfunc;
      lua_KContext ctx;  /* context info. in case of yields */
    } c; // 只对 C 函数有效，保存了当前 C 函数执行的一些信息，比如 continuation、旧的 error function 等
  } u;
  union {
    int funcidx;  /* 只对 Lua 函数有效，保存当前函数调用的索引位置 called-function index */
    int nyield;  /* 只对协程有效，保存协程已经 yield 的次数 number of values yielded */
    int nres;  /*  当前函数调用返回值的数量 number of values returned */
    struct {  /* info about transferred values (for call/return hooks) */
      unsigned short ftransfer;  /* offset of first value transferred */
      unsigned short ntransfer;  /* number of values transferred */
    } transferinfo; // 用于保存调用钩子函数时传递的信息，比如转移值的偏移量和数量
  } u2; // 联合体，用于保存各种类型函数的返回值信息
  short nresults;  /* 期望从当前函数返回的值的数量 expected number of results from this function */
  unsigned short callstatus; // 调用状态，有多个预定义的状态值，包括 CIST_HOOKED、CIST_YPCALL、CIST_LUA 等
} CallInfo;


/*
** Bits in CallInfo status
*/
#define CIST_OAH	(1<<0)	/* original value of 'allowhook' */
#define CIST_C		(1<<1)	/* call is running a C function */
#define CIST_FRESH	(1<<2)	/* call is on a fresh "luaV_execute" frame */
#define CIST_HOOKED	(1<<3)	/* call is running a debug hook */
#define CIST_YPCALL	(1<<4)	/* doing a yieldable protected call */
#define CIST_TAIL	(1<<5)	/* call was tail called */
#define CIST_HOOKYIELD	(1<<6)	/* last hook called yielded */
#define CIST_FIN	(1<<7)	/* function "called" a finalizer */
#define CIST_TRAN	(1<<8)	/* 'ci' has transfer information */
#define CIST_CLSRET	(1<<9)  /* function is closing tbc variables */
/* Bits 10-12 are used for CIST_RECST (see below) */
#define CIST_RECST	10
#if defined(LUA_COMPAT_LT_LE)
#define CIST_LEQ	(1<<13)  /* using __lt for __le */
#endif


/*
** Field CIST_RECST stores the "recover status", used to keep the error
** status while closing to-be-closed variables in coroutines, so that
** Lua can correctly resume after an yield from a __close method called
** because of an error.  (Three bits are enough for error status.)
*/
#define getcistrecst(ci)     (((ci)->callstatus >> CIST_RECST) & 7)
#define setcistrecst(ci,st)  \
  check_exp(((st) & 7) == (st),   /* status must fit in three bits */  \
            ((ci)->callstatus = ((ci)->callstatus & ~(7 << CIST_RECST))  \
                                                  | ((st) << CIST_RECST)))


/* active function is a Lua function */
#define isLua(ci)	(!((ci)->callstatus & CIST_C))

/* call is running Lua code (not a hook) */
#define isLuacode(ci)	(!((ci)->callstatus & (CIST_C | CIST_HOOKED)))

/* assume that CIST_OAH has offset 0 and that 'v' is strictly 0/1 */
#define setoah(st,v)	((st) = ((st) & ~CIST_OAH) | (v))
#define getoah(st)	((st) & CIST_OAH)


/*
** 'global state', shared by all threads of this state
*/
typedef struct global_State {
  lua_Alloc frealloc;  /* function to reallocate memory */
  void *ud;         /* auxiliary data to 'frealloc' */
  l_mem totalbytes;  /* number of bytes currently allocated - GCdebt */
  l_mem GCdebt;  /* bytes allocated not yet compensated by the collector | 内部感知的内存大小 */
  lu_mem GCestimate;  /* an estimate of the non-garbage memory in use */
  lu_mem lastatomic;  /* see function 'genstep' in file 'lgc.c' */
  stringtable strt;  /* hash table for strings 全局字符串表, 字符串池化，使得整个虚拟机中短字符串只有一份实例 , 是一个 hash 表 */
  TValue l_registry; /* 注册表（管理全局数据） ，Registry表可以用debug.getregistry获取。注册表 就是一个全局的table（即整个虚拟机中只有一个注册表），它只能被C代码访问，通常，它用来保存 那些需要在几个模块中共享的数据。比如通过luaL_newmetatable创建的元表就是放在全局的注册表中。 */
  TValue nilvalue;  /* a nil value */
  unsigned int seed;  /* randomized seed for hashes 启动时生成的一个随机数种子 , 主要是在求字符串哈希时使用 */
  lu_byte currentwhite;
  lu_byte gcstate;  /* state of garbage collector */
  lu_byte gckind;  /* kind of GC running */
  lu_byte gcstopem;  /* stops emergency collections */
  lu_byte genminormul;  /* control for minor generational collections */
  lu_byte genmajormul;  /* control for major generational collections */
  lu_byte gcstp;  /* control whether GC is running */
  lu_byte gcemergency;  /* true if this is an emergency collection */
  lu_byte gcpause;  /* size of pause between successive GCs */
  lu_byte gcstepmul;  /* GC "speed" */
  lu_byte gcstepsize;  /* (log2 of) GC granularity */
  GCObject *allgc;  /* list of all collectable objects */
  GCObject **sweepgc;  /* current position of sweep in list */
  GCObject *finobj;  /* list of collectable objects with finalizers */
  GCObject *gray;  /* list of gray objects */
  GCObject *grayagain;  /* list of objects to be traversed atomically */
  GCObject *weak;  /* list of tables with weak values */
  GCObject *ephemeron;  /* list of ephemeron tables (weak keys) */
  GCObject *allweak;  /* list of all-weak tables */
  GCObject *tobefnz;  /* list of userdata to be GC */
  GCObject *fixedgc;  /* list of objects not to be collected */
  /* fields for generational collector */
  GCObject *survival;  /* start of objects that survived one GC cycle */
  GCObject *old1;  /* start of old1 objects */
  GCObject *reallyold;  /* objects more than one cycle old ("really old") */
  GCObject *firstold1;  /* first OLD1 object in the list (if any) */
  GCObject *finobjsur;  /* list of survival objects with finalizers */
  GCObject *finobjold1;  /* list of old1 objects with finalizers */
  GCObject *finobjrold;  /* list of really old objects with finalizers */
  struct lua_State *twups;  /* list of threads with open upvalues */
  lua_CFunction panic;  /* to be called in unprotected errors */
  struct lua_State *mainthread; /* 主lua_State。在一个独立的lua虚拟机里, global_State是一个全局的结构, 而lua_State可以有多个。 lua_newstate会创建出一个lua_State, 绑在 lua_State *mainthread.可以说是主线程、主执行栈。 */
  TString *memerrmsg;  /* message for memory-allocation errors */
  TString *tmname[TM_N];  /* array with tag-method names 预定义了元方法名字数组 */
  struct Table *mt[LUA_NUMTAGS];  /* metatables for basic types 存储了基础类型的元表信息。每一个Lua 的基本数据类型都有一个元表。  */
  TString *strcache[STRCACHE_N][STRCACHE_M];  /* cache for strings in API */
  lua_WarnFunction warnf;  /* warning function */
  void *ud_warn;         /* auxiliary data to 'warnf' */
} global_State;


/*
** 'per thread' state
*/
struct lua_State {
  CommonHeader; //  Lua 对象系统中的公共头部，用于识别对象类型和 GC 回收等
  lu_byte status; // 当前状态，包括运行中、暂停、错误等
  lu_byte allowhook; // 是否允许调试钩子
  unsigned short nci;  /* 当前状态机的调用信息（Callinfo）栈中的调用信息个数 number of items in 'ci' list */
  StkId top;  /* 栈顶指针，即堆栈中最后一个空闲的位置 first free slot in the stack */
  global_State *l_G; // 全局状态信息
  CallInfo *ci;  /* 当前的调用信息（Callinfo） call info for current function */
  StkId stack_last;  /*  栈的结尾位置（最后一个元素的下一个位置） end of stack (last element + 1) */
  StkId stack;  /* 栈的开始位置 stack base */
  UpVal *openupval;  /* 当前打开的 Upvalue 列表 list of open upvalues in this stack */
  StkId tbclist;  /* 待关闭的 Upvalue 列表 list of to-be-closed variables */
  GCObject *gclist; // 待 GC 的对象列表
  struct lua_State *twups;  /* 当前线程的 open upvalue 列表 list of threads with open upvalues */
  struct lua_longjmp *errorJmp;  /* 当前错误恢复点，用于处理 Lua 错误 current error recover point */
  CallInfo base_ci;  /* 根据调用信息（Callinfo）创建的一个基础的调用信息（Callinfo）结构体，即第一个被 C 调用的函数的调用信息 CallInfo for first level (C calling Lua) */
  volatile lua_Hook hook; // 当前调试钩子函数
  ptrdiff_t errfunc;  /* 当前错误处理函数的栈索引 current error handling function (stack index) */
  l_uint32 nCcalls;  /* 嵌套的 C 函数调用数量 number of nested (non-yieldable | C)  calls */
  int oldpc;  /* 上一个被跟踪的指令位置 last pc traced */
  int basehookcount; // 钩子函数调用次数的基准值
  int hookcount; // 计数当前的钩子函数调用次数
  volatile l_signalT hookmask; // 钩子函数的类型掩码
};


#define G(L)	(L->l_G)

/*
** 'g->nilvalue' being a nil value flags that the state was completely
** build.
*/
#define completestate(g)	ttisnil(&g->nilvalue)


/*
** Union of all collectable objects (only for conversions)
** ISO C99, 6.5.2.3 p.5:
** "if a union contains several structures that share a common initial
** sequence [...], and if the union object currently contains one
** of these structures, it is permitted to inspect the common initial
** part of any of them anywhere that a declaration of the complete type
** of the union is visible."
*/
union GCUnion {
  GCObject gc;  /* common header */
  struct TString ts;
  struct Udata u;
  union Closure cl;
  struct Table h;
  struct Proto p;
  struct lua_State th;  /* thread */
  struct UpVal upv;
};


/*
** ISO C99, 6.7.2.1 p.14:
** "A pointer to a union object, suitably converted, points to each of
** its members [...], and vice versa."
*/
#define cast_u(o)	cast(union GCUnion *, (o))

/* macros to convert a GCObject into a specific value */
#define gco2ts(o)  \
	check_exp(novariant((o)->tt) == LUA_TSTRING, &((cast_u(o))->ts))
#define gco2u(o)  check_exp((o)->tt == LUA_VUSERDATA, &((cast_u(o))->u))
#define gco2lcl(o)  check_exp((o)->tt == LUA_VLCL, &((cast_u(o))->cl.l))
#define gco2ccl(o)  check_exp((o)->tt == LUA_VCCL, &((cast_u(o))->cl.c))
#define gco2cl(o)  \
	check_exp(novariant((o)->tt) == LUA_TFUNCTION, &((cast_u(o))->cl))
#define gco2t(o)  check_exp((o)->tt == LUA_VTABLE, &((cast_u(o))->h))
#define gco2p(o)  check_exp((o)->tt == LUA_VPROTO, &((cast_u(o))->p))
#define gco2th(o)  check_exp((o)->tt == LUA_VTHREAD, &((cast_u(o))->th))
#define gco2upv(o)	check_exp((o)->tt == LUA_VUPVAL, &((cast_u(o))->upv))


/*
** macro to convert a Lua object into a GCObject
** (The access to 'tt' tries to ensure that 'v' is actually a Lua object.)
*/
#define obj2gco(v)	check_exp((v)->tt >= LUA_TSTRING, &(cast_u(v)->gc))


/* actual number of total bytes allocated */
#define gettotalbytes(g)	cast(lu_mem, (g)->totalbytes + (g)->GCdebt)

LUAI_FUNC void luaE_setdebt (global_State *g, l_mem debt);
LUAI_FUNC void luaE_freethread (lua_State *L, lua_State *L1);
LUAI_FUNC CallInfo *luaE_extendCI (lua_State *L);
LUAI_FUNC void luaE_freeCI (lua_State *L);
LUAI_FUNC void luaE_shrinkCI (lua_State *L);
LUAI_FUNC void luaE_checkcstack (lua_State *L);
LUAI_FUNC void luaE_incCstack (lua_State *L);
LUAI_FUNC void luaE_warning (lua_State *L, const char *msg, int tocont);
LUAI_FUNC void luaE_warnerror (lua_State *L, const char *where);
LUAI_FUNC int luaE_resetthread (lua_State *L, int status);


#endif

