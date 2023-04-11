/*
** $Id: lobject.h $
** Type definitions for Lua objects
** See Copyright Notice in lua.h
*/

/*
 对象操作的一些函数
*/

#ifndef lobject_h
#define lobject_h

#include <stdarg.h>

#include "llimits.h"
#include "lua.h"

/*
** Extra types for collectable non-values
*/
#define LUA_TUPVAL LUA_NUMTYPES /* upvalues */
#define LUA_TPROTO (LUA_NUMTYPES + 1) /* function prototypes */
#define LUA_TDEADKEY (LUA_NUMTYPES + 2) /* removed keys in tables */

/*
** number of all possible types (including LUA_TNONE but excluding DEADKEY)
*/
#define LUA_TOTALTYPES (LUA_TPROTO + 2)

/*
** tags for Tagged Values have the following use of bits:
** bits 0-3: actual tag (a LUA_T* constant)
** bits 4-5: variant bits
** bit 6: whether value is collectable
*/

/* t 是原基本类型(低 4 位), v 是扩展类型(高 4 位); add variant bits to a type */
#define makevariant(t, v) ((t) | ((v) << 4))

/// @brief Union of all Lua values
/// @param gc collectable objects 对应有 CommonHeader 的对象, 包括 TString, Udata, Udata0, Proto, UpVal, Closure, Table
/// @param p light userdata 不需要 lua 来关心数据的生存期, 不被 gc 回收
/// @param f int (*) (lua_State *L) 没有 upvalues, 就是一个普通的 c 函数, 所以不用 gc
/// @param i long long 不被 gc 回收
/// @param n double 不被 gc 回收
typedef union Value {
    struct GCObject* gc; /* collectable objects */
    void* p; /* light userdata */
    lua_CFunction f; /* light C functions */
    lua_Integer i; /* integer numbers */
    lua_Number n; /* float numbers */
} Value;

/*
** Tagged Values. This is the basic representation of values in Lua:
** an actual value plus a tag with its type.
*/

#define TValuefields                                                                                                                                                                                   \
    Value value_;                                                                                                                                                                                      \
    lu_byte tt_

typedef struct TValue {
    TValuefields;
} TValue;

#define val_(o) ((o)->value_)
#define valraw(o) (val_(o))

// o 的细分类型(tt_); raw type tag of a TValue
#define rawtt(o) ((o)->tt_)

// 细分类型(tag)的低 4 位, 细分类型的大类; tag with no variants (bits 0-3)
#define novariant(t) ((t)&0x0F)

/* type tag of a TValue (bits 0-3 for tags + variant bits 4-5) */
#define withvariant(t) ((t)&0x3F)
#define ttypetag(o) withvariant(rawtt(o))

// o 属于的大类型; type of a TValue
#define ttype(o) (novariant(rawtt(o)))

/* Macros to test type */
// o 是不是 t 这种细分类型(tag)
#define checktag(o, t) (rawtt(o) == (t))
// o 是不是 t 这种类型(type)
#define checktype(o, t) (ttype(o) == (t))

/* Macros for internal tests */

/* collectable object has the same tag as the original value */
#define righttt(obj) (ttypetag(obj) == gcvalue(obj)->tt)

/*
** Any value being manipulated by the program either is non
** collectable, or the collectable object has the right tag
** and it is not dead. The option 'L == NULL' allows other
** macros using this one to be used where L is not available.
*/
#define checkliveness(L, obj) ((void)L, lua_longassert(!iscollectable(obj) || (righttt(obj) && (L == NULL || !isdead(G(L), gcvalue(obj))))))

/* Macros to set values */

/* set a value's tag */
#define settt_(o, t) ((o)->tt_ = (t))

/// @brief 两个 TValue 类型的对象, 把 obj2 的 value_ 与 tt_ 都复制到 obj1 ; main macro to copy values (from 'obj2' to 'obj1')
#define setobj(L, obj1, obj2)                                                                                                                                                                          \
    {                                                                                                                                                                                                  \
        TValue* io1 = (obj1);                                                                                                                                                                          \
        const TValue* io2 = (obj2);                                                                                                                                                                    \
        io1->value_ = io2->value_;                                                                                                                                                                     \
        settt_(io1, io2->tt_);                                                                                                                                                                         \
        checkliveness(L, io1);                                                                                                                                                                         \
        lua_assert(!isnonstrictnil(io1));                                                                                                                                                              \
    }

/*
** Different types of assignments, according to source and destination.
** (They are mostly equal now, but may be different in the future.)
*/

/* from stack to stack 就是 o2 的值给 o1 */
#define setobjs2s(L, o1, o2) setobj(L, s2v(o1), s2v(o2))
/* to stack (not from same stack) 过程就是把 o2 赋值给 o1 */
#define setobj2s(L, o1, o2) setobj(L, s2v(o1), o2)
/* from table to same table */
#define setobjt2t setobj
/* to new object */
#define setobj2n setobj
/* to table 把 给出的 value 赋值给 table 指定的 node (类型与值)*/
#define setobj2t setobj

/*
** Entries in a Lua stack. Field 'tbclist' forms a list of all
** to-be-closed variables active in this stack. Dummy entries are
** used when the distance between two tbc variables does not fit
** in an unsigned short. They are represented by delta==0, and
** their real delta is always the maximum value that fits in
** that field.
*/
typedef union StackValue {
    TValue val;
    struct {
        TValuefields;
        unsigned short delta;
    } tbclist;
} StackValue;

/* index to stack elements */
typedef StackValue* StkId;

/* convert a 'StackValue' to a 'TValue' */
#define s2v(o) (&(o)->val)

/*
** {==================================================================
** Nil
** ===================================================================
*/

// TValue 的 tt_ 为些值时, 改值表示 nil; Standard nil
#define LUA_VNIL makevariant(LUA_TNIL, 0)

/* Empty slot (which might be different from a slot containing nil) */
#define LUA_VEMPTY makevariant(LUA_TNIL, 1)

/* Value returned for a key not found in a table (absent key) */
#define LUA_VABSTKEY makevariant(LUA_TNIL, 2)

/* macro to test for (any kind of) nil */
#define ttisnil(v) checktype((v), LUA_TNIL)

/* macro to test for a standard nil */
#define ttisstrictnil(o) checktag((o), LUA_VNIL)

// obj 要是 TValue 指针, 把 TValue 的 tt_ 设置成 LUA_VNIL (0)
#define setnilvalue(obj) settt_(obj, LUA_VNIL)

#define isabstkey(v) checktag((v), LUA_VABSTKEY)

/*
** macro to detect non-standard nils (used only in assertions)
*/
#define isnonstrictnil(v) (ttisnil(v) && !ttisstrictnil(v))

/*
** By default, entries with any kind of nil are considered empty.
** (In any definition, values associated with absent keys must also
** be accepted as empty.)
*/
#define isempty(v) ttisnil(v)

/* macro defining a value corresponding to an absent key */
#define ABSTKEYCONSTANT {NULL}, LUA_VABSTKEY

/* mark an entry as empty */
#define setempty(v) settt_(v, LUA_VEMPTY)

/* }================================================================== */

/*
** {==================================================================
** Booleans
** ===================================================================
*/

#define LUA_VFALSE makevariant(LUA_TBOOLEAN, 0)
#define LUA_VTRUE makevariant(LUA_TBOOLEAN, 1)

#define ttisboolean(o) checktype((o), LUA_TBOOLEAN)
#define ttisfalse(o) checktag((o), LUA_VFALSE)
#define ttistrue(o) checktag((o), LUA_VTRUE)

#define l_isfalse(o) (ttisfalse(o) || ttisnil(o))

// obj->tt_ = false
#define setbfvalue(obj) settt_(obj, LUA_VFALSE)
// obj->tt_ = true
#define setbtvalue(obj) settt_(obj, LUA_VTRUE)

/* }================================================================== */

/*
** {==================================================================
** Threads
** ===================================================================
*/

#define LUA_VTHREAD makevariant(LUA_TTHREAD, 0)

#define ttisthread(o) checktag((o), ctb(LUA_VTHREAD))

#define thvalue(o) check_exp(ttisthread(o), gco2th(val_(o).gc))

#define setthvalue(L, obj, x)                                                                                                                                                                          \
    {                                                                                                                                                                                                  \
        TValue* io = (obj);                                                                                                                                                                            \
        lua_State* x_ = (x);                                                                                                                                                                           \
        val_(io).gc = obj2gco(x_);                                                                                                                                                                     \
        settt_(io, ctb(LUA_VTHREAD));                                                                                                                                                                  \
        checkliveness(L, io);                                                                                                                                                                          \
    }

#define setthvalue2s(L, o, t) setthvalue(L, s2v(o), t)

/* }================================================================== */

/*
** {==================================================================
** Collectable Objects
** ===================================================================
*/

/*
** Common Header for all collectable objects (in macro form, to be
** included in other objects)
@param tt 数据的类型
*/
#define CommonHeader                                                                                                                                                                                   \
    struct GCObject* next;                                                                                                                                                                             \
    lu_byte tt;                                                                                                                                                                                        \
    lu_byte marked

/* Common type for all collectable objects
@param tt 一个字节的类型标志,用于记录对象的具体类型,以便在垃圾回收时做出不同的处理
@param marked 一个字节的标记,用于记录对象是否被标记为可达,以便在垃圾回收时判断对象是否需要被回收
@param GCObject*next 指向下一个垃圾回收对象的指针,用于将所有的垃圾回收对象串联起来,形成一个链表
*/
typedef struct GCObject {
    CommonHeader;
} GCObject;

/* Bit mark for collectable types */
#define BIT_ISCOLLECTABLE (1 << 6)

#define iscollectable(o) (rawtt(o) & BIT_ISCOLLECTABLE)

/* mark a tag as collectable */
#define ctb(t) ((t) | BIT_ISCOLLECTABLE)

#define gcvalue(o) check_exp(iscollectable(o), val_(o).gc)

#define gcvalueraw(v) ((v).gc)

#define setgcovalue(L, obj, x)                                                                                                                                                                         \
    {                                                                                                                                                                                                  \
        TValue* io = (obj);                                                                                                                                                                            \
        GCObject* i_g = (x);                                                                                                                                                                           \
        val_(io).gc = i_g;                                                                                                                                                                             \
        settt_(io, ctb(i_g->tt));                                                                                                                                                                      \
    }

/* }================================================================== */

/*
** {==================================================================
** Numbers
** ===================================================================
*/

/* Variant tags for numbers */
#define LUA_VNUMINT makevariant(LUA_TNUMBER, 0) /* integer numbers */
#define LUA_VNUMFLT makevariant(LUA_TNUMBER, 1) /* float numbers */

#define ttisnumber(o) checktype((o), LUA_TNUMBER)
#define ttisfloat(o) checktag((o), LUA_VNUMFLT)
#define ttisinteger(o) checktag((o), LUA_VNUMINT)

#define nvalue(o) check_exp(ttisnumber(o), (ttisinteger(o) ? cast_num(ivalue(o)) : fltvalue(o)))
#define fltvalue(o) check_exp(ttisfloat(o), val_(o).n)
#define ivalue(o) check_exp(ttisinteger(o), val_(o).i)

#define fltvalueraw(v) ((v).n)
#define ivalueraw(v) ((v).i)

/// @brief 把对象设置成浮点数
#define setfltvalue(obj, x)                                                                                                                                                                            \
    {                                                                                                                                                                                                  \
        TValue* io = (obj);                                                                                                                                                                            \
        val_(io).n = (x);                                                                                                                                                                              \
        settt_(io, LUA_VNUMFLT);                                                                                                                                                                       \
    }

#define chgfltvalue(obj, x)                                                                                                                                                                            \
    {                                                                                                                                                                                                  \
        TValue* io = (obj);                                                                                                                                                                            \
        lua_assert(ttisfloat(io));                                                                                                                                                                     \
        val_(io).n = (x);                                                                                                                                                                              \
    }

/// @brief 把对象设置成整数
#define setivalue(obj, x)                                                                                                                                                                              \
    {                                                                                                                                                                                                  \
        TValue* io = (obj);                                                                                                                                                                            \
        val_(io).i = (x);                                                                                                                                                                              \
        settt_(io, LUA_VNUMINT);                                                                                                                                                                       \
    }

#define chgivalue(obj, x)                                                                                                                                                                              \
    {                                                                                                                                                                                                  \
        TValue* io = (obj);                                                                                                                                                                            \
        lua_assert(ttisinteger(io));                                                                                                                                                                   \
        val_(io).i = (x);                                                                                                                                                                              \
    }

/* }================================================================== */

/*
** {==================================================================
** Strings
** ===================================================================
*/

/* Variant tags for strings 这个小类型区分放在类型字节的高四位, 所以为外部 API 所不可见 */
#define LUA_VSHRSTR makevariant(LUA_TSTRING, 0) /* short strings */
#define LUA_VLNGSTR makevariant(LUA_TSTRING, 1) /* long strings */

#define ttisstring(o) checktype((o), LUA_TSTRING)
#define ttisshrstring(o) checktag((o), ctb(LUA_VSHRSTR))
#define ttislngstring(o) checktag((o), ctb(LUA_VLNGSTR))

#define tsvalueraw(v) (gco2ts((v).gc))

#define tsvalue(o) check_exp(ttisstring(o), gco2ts(val_(o).gc))

// obj 指向 x 指向的内存
#define setsvalue(L, obj, x)                                                                                                                                                                           \
    {                                                                                                                                                                                                  \
        TValue* io = (obj);                                                                                                                                                                            \
        TString* x_ = (x);                                                                                                                                                                             \
        val_(io).gc = obj2gco(x_);                                                                                                                                                                     \
        settt_(io, ctb(x_->tt));                                                                                                                                                                       \
        checkliveness(L, io);                                                                                                                                                                          \
    }

/* set a string to the stack */
#define setsvalue2s(L, o, s) setsvalue(L, s2v(o), s)

/* set a string to a new object */
#define setsvalue2n setsvalue

/// @brief Header for a string value.
typedef struct TString {
    CommonHeader;
    lu_byte extra; /*reserved words for short strings; "has hash" for longs */
    lu_byte shrlen; /* length for short strings */
    unsigned int hash; /* 字符串的哈希值,用于字符串的查找和比较操作 */
    union {
        size_t lnglen; /* TString 是长串时, 表示长符的长度  length for long strings */
        struct TString* hnext; /* 短串时, 某个桶中的中, 当作链表使用 linked list for hash table */
    } u;
    char contents[1]; /* 一个柔性数组 字符串的具体内容,以 null 结尾 */
} TString;

/*
** Get the actual string (array of bytes) from a 'TString'.
*/
#define getstr(ts) ((ts)->contents) // 拿到 TString 里 C 字符串指针 contents

/* 拿到 TString 里 C 字符串指针 contents; get the actual string (array of bytes) from a Lua value */
#define svalue(o) getstr(tsvalue(o))

/* get string length from 'TString *s' */
#define tsslen(s) ((s)->tt == LUA_VSHRSTR ? (s)->shrlen : (s)->u.lnglen)

/* TValue 中字符串的长度; get string length from 'TValue *o' */
#define vslen(o) tsslen(tsvalue(o))

/* }================================================================== */

/*
** {==================================================================
** Userdata
** ===================================================================
*/

/*
** Light userdata should be a variant of userdata, but for compatibility
** reasons they are also different types.
*/
#define LUA_VLIGHTUSERDATA makevariant(LUA_TLIGHTUSERDATA, 0)

#define LUA_VUSERDATA makevariant(LUA_TUSERDATA, 0)

#define ttislightuserdata(o) checktag((o), LUA_VLIGHTUSERDATA)
#define ttisfulluserdata(o) checktag((o), ctb(LUA_VUSERDATA))

#define pvalue(o) check_exp(ttislightuserdata(o), val_(o).p)
#define uvalue(o) check_exp(ttisfulluserdata(o), gco2u(val_(o).gc))

#define pvalueraw(v) ((v).p)

#define setpvalue(obj, x)                                                                                                                                                                              \
    {                                                                                                                                                                                                  \
        TValue* io = (obj);                                                                                                                                                                            \
        val_(io).p = (x);                                                                                                                                                                              \
        settt_(io, LUA_VLIGHTUSERDATA);                                                                                                                                                                \
    }

#define setuvalue(L, obj, x)                                                                                                                                                                           \
    {                                                                                                                                                                                                  \
        TValue* io = (obj);                                                                                                                                                                            \
        Udata* x_ = (x);                                                                                                                                                                               \
        val_(io).gc = obj2gco(x_);                                                                                                                                                                     \
        settt_(io, ctb(LUA_VUSERDATA));                                                                                                                                                                \
        checkliveness(L, io);                                                                                                                                                                          \
    }

/* Ensures that addresses after this type are always fully aligned. */
typedef union UValue {
    TValue uv;
    LUAI_MAXALIGN; /* ensures maximum alignment for udata bytes */
} UValue;

/*
** Header for userdata with user values;
** memory area follows the end of this structure.
*/
typedef struct Udata {
    CommonHeader;
    unsigned short nuvalue; /* number of user values */
    size_t len; /* number of bytes */
    struct Table* metatable;
    GCObject* gclist;
    UValue uv[1]; /* user values */
} Udata;

/*
** Header for userdata with no user values. These userdata do not need
** to be gray during GC, and therefore do not need a 'gclist' field.
** To simplify, the code always use 'Udata' for both kinds of userdata,
** making sure it never accesses 'gclist' on userdata with no user values.
** This structure here is used only to compute the correct size for
** this representation. (The 'bindata' field in its end ensures correct
** alignment for binary data following this header.)
*/
typedef struct Udata0 {
    CommonHeader;
    unsigned short nuvalue; /* number of user values */
    size_t len; /* number of bytes */
    struct Table* metatable;
    union {
        LUAI_MAXALIGN;
    } bindata;
} Udata0;

/* compute the offset of the memory area of a userdata */
#define udatamemoffset(nuv) ((nuv) == 0 ? offsetof(Udata0, bindata) : offsetof(Udata, uv) + (sizeof(UValue) * (nuv)))

/* get the address of the memory block inside 'Udata' */
#define getudatamem(u) (cast_charp(u) + udatamemoffset((u)->nuvalue))

/* compute the size of a userdata */
#define sizeudata(nuv, nb) (udatamemoffset(nuv) + (nb))

/* }================================================================== */

/*
** {==================================================================
** Prototypes
** ===================================================================
*/

#define LUA_VPROTO makevariant(LUA_TPROTO, 0)

/// @brief Description of an upvalue for function prototypes
/// @param name 表示 Upvalue 的名称, 主要用于调试信息
/// @param instack Upvalue 是否存在于函数的栈空间（即寄存器）中.如果存在,则为 1,否则为 0.
/// @param idx Upvalue 在栈空间或外部函数的 Upvalue 列表中的索引.如果上值存在于栈空间中,则为其在栈中的索引;否则为其在外部函数的上值列表中的索引.
/// @param kind  0 表示全局变量, 1 表示局部变量, 2 表示 Upvalue, 3 表示表字段
typedef struct Upvaldesc {
    TString* name; /* upvalue name (for debug information) */
    lu_byte instack; /* whether it is in stack (register) */
    lu_byte idx; /* index of upvalue (in stack or in outer function's list) */
    lu_byte kind; /* kind of corresponding variable */
} Upvaldesc;

/*
** Description of a local variable for function prototypes
** (used for debug information)
*/
typedef struct LocVar {
    TString* varname;
    int startpc; /* first point where variable is active */
    int endpc; /* first point where variable is dead */
} LocVar;

/*
** Associates the absolute line source for a given instruction ('pc').
** The array 'lineinfo' gives, for each instruction, the difference in
** lines from the previous instruction. When that difference does not
** fit into a byte, Lua saves the absolute line for that instruction.
** (Lua also saves the absolute line periodically, to speed up the
** computation of a line number: we can use binary search in the
** absolute-line array, but we must traverse the 'lineinfo' array
** linearly to compute a line.)
*/
typedef struct AbsLineInfo {
    int pc;
    int line;
} AbsLineInfo;

///@brief Function Prototypes
typedef struct Proto {
    CommonHeader; /* 通用对象头部 */
    lu_byte numparams; /* 函数的固定参数个数 number of fixed (named) parameters */
    lu_byte is_vararg; /* 是否为变长参数函数 */
    lu_byte maxstacksize; /* 表示该函数执行时最多需要多少个栈空间(寄存器, 对于函数来说,栈就是寄存器了) number of registers needed by this function */
    int sizeupvalues; /* 函数中的Upvalue数量 size of 'upvalues' */
    int sizek; /* 常量表中元素的个数 size of 'k' */
    int sizecode; /* code 数组的大小 */
    int sizelineinfo; /* 行号信息表中元素的个数 */
    int sizep; /* 函数原型表中元素的个数（用于表示内嵌函数） size of 'p' */
    int sizelocvars; /* 局部变量表中元素的个数 */
    int sizeabslineinfo; /* 绝对行号信息表中元素的个数 size of 'abslineinfo' */
    int linedefined; /* 函数定义在源代码中的第一行行号 debug information  */
    int lastlinedefined; /* 函数定义在源代码中的最后一行行号 debug information  */
    TValue* k; /* 常量表,用于存放函数中用到的常量(就是字面量,只能是数字,布尔值,字符串,和nil这些基本类型) constants used by the function */
    Instruction* code; /* 指令表,存放函数中的指令 opcodes */
    struct Proto** p; /* 使用**,是因为一个函数里可以写多个函数,是一个树结构 functions defined inside the function */
    Upvaldesc* upvalues; /* 存储函数中用到的Upvalue信息 upvalue information */
    ls_byte* lineinfo; /* 行号信息表,存储每个指令对应的源代码行号 information about source lines (debug information) */
    AbsLineInfo* abslineinfo; /* 绝对行号信息表,存储每个指令对应的源代码绝对行号 idem */
    LocVar* locvars; /* 局部变量表,存储函数中局部变量的信息(固定参数,可变参数,和本地变量) information about local variables (debug information) */
    TString* source; /* 指向源代码文件名的指针 used for debug information */
    GCObject* gclist; /* GC链表节点 */
} Proto;

/* }================================================================== */

/*
** {==================================================================
** Functions
** ===================================================================
*/

#define LUA_VUPVAL makevariant(LUA_TUPVAL, 0)

/* Variant tags for functions */
#define LUA_VLCL makevariant(LUA_TFUNCTION, 0) /* 0000 1010; Lua closure */
#define LUA_VLCF makevariant(LUA_TFUNCTION, 1) /* 0001 1010; light C function */
#define LUA_VCCL makevariant(LUA_TFUNCTION, 2) /* 0010 1010; C closure */

#define ttisfunction(o) checktype(o, LUA_TFUNCTION)
#define ttisLclosure(o) checktag((o), ctb(LUA_VLCL))
#define ttislcf(o) checktag((o), LUA_VLCF)
#define ttisCclosure(o) checktag((o), ctb(LUA_VCCL))
#define ttisclosure(o) (ttisLclosure(o) || ttisCclosure(o))

#define isLfunction(o) ttisLclosure(o)

#define clvalue(o) check_exp(ttisclosure(o), gco2cl(val_(o).gc))
#define clLvalue(o) check_exp(ttisLclosure(o), gco2lcl(val_(o).gc))
#define fvalue(o) check_exp(ttislcf(o), val_(o).f)
#define clCvalue(o) check_exp(ttisCclosure(o), gco2ccl(val_(o).gc))

#define fvalueraw(v) ((v).f)

#define setclLvalue(L, obj, x)                                                                                                                                                                         \
    {                                                                                                                                                                                                  \
        TValue* io = (obj);                                                                                                                                                                            \
        LClosure* x_ = (x);                                                                                                                                                                            \
        val_(io).gc = obj2gco(x_);                                                                                                                                                                     \
        settt_(io, ctb(LUA_VLCL));                                                                                                                                                                     \
        checkliveness(L, io);                                                                                                                                                                          \
    }

/// @brief 把 cl 锚定到栈中 o 的位置上
#define setclLvalue2s(L, o, cl) setclLvalue(L, s2v(o), cl)

#define setfvalue(obj, x)                                                                                                                                                                              \
    {                                                                                                                                                                                                  \
        TValue* io = (obj);                                                                                                                                                                            \
        val_(io).f = (x);                                                                                                                                                                              \
        settt_(io, LUA_VLCF);                                                                                                                                                                          \
    }

#define setclCvalue(L, obj, x)                                                                                                                                                                         \
    {                                                                                                                                                                                                  \
        TValue* io = (obj);                                                                                                                                                                            \
        CClosure* x_ = (x);                                                                                                                                                                            \
        val_(io).gc = obj2gco(x_);                                                                                                                                                                     \
        settt_(io, ctb(LUA_VCCL));                                                                                                                                                                     \
        checkliveness(L, io);                                                                                                                                                                          \
    }

///@brief Upvalues for Lua closures
typedef struct UpVal {
    CommonHeader; /* 通用的 GCObject 结构体头部 */
    lu_byte tbc; /* true 表示该 Upvalue 是一个 to-be-closed 变量,即需要执行清理动作 true if it represents a to-be-closed variable */
    TValue* v; /* 如果该 Upvalue 关联的局部变量仍在栈上,则指向该局部变量的位置;否则,指向该 Upvalue 的值 points to stack or to its own value */
    union {
        struct { /* (when open) */
            struct UpVal* next; /* linked list */
            struct UpVal** previous; // 指向前一个结点指针的指针
        } open; /* 当该 Upvalue 关联的局部变量仍在栈上时,它表示一个链表节点,其中 next 指向下一个 Upvalue */
        TValue value; /* 当该 Upvalue 关联的局部变量已经从栈上移除时,value 就是 Upvalue 的值 the value (when closed) */
    } u;
} UpVal;

#define ClosureHeader                                                                                                                                                                                  \
    CommonHeader;                                                                                                                                                                                      \
    lu_byte nupvalues;                                                                                                                                                                                 \
    GCObject* gclist

typedef struct CClosure {
    ClosureHeader;
    lua_CFunction f;
    TValue upvalue[1]; /* list of upvalues */
} CClosure;

typedef struct LClosure {
    ClosureHeader;
    struct Proto* p;
    UpVal* upvals[1]; /* 这是一个指针数组 list of upvalues */
} LClosure;

typedef union Closure {
    CClosure c;
    LClosure l;
} Closure;

#define getproto(o) (clLvalue(o)->p)

/* }================================================================== */

/*
** {==================================================================
** Tables
** ===================================================================
*/

#define LUA_VTABLE makevariant(LUA_TTABLE, 0)

#define ttistable(o) checktag((o), ctb(LUA_VTABLE))

// 拿到 Tvalue 中 Value 中 gc 指针指向数据的 h 部分
#define hvalue(o) check_exp(ttistable(o), gco2t(val_(o).gc))

#define sethvalue(L, obj, x)                                                                                                                                                                           \
    {                                                                                                                                                                                                  \
        TValue* io = (obj);                                                                                                                                                                            \
        Table* x_ = (x);                                                                                                                                                                               \
        val_(io).gc = obj2gco(x_);                                                                                                                                                                     \
        settt_(io, ctb(LUA_VTABLE));                                                                                                                                                                   \
        checkliveness(L, io);                                                                                                                                                                          \
    }

#define sethvalue2s(L, o, h) sethvalue(L, s2v(o), h)

/*
** Nodes for Hash tables: A pack of two TValue's (key-value pairs)
** plus a 'next' field to link colliding entries. The distribution
** of the key's fields ('key_tt' and 'key_val') not forming a proper
** 'TValue' allows for a smaller size for 'Node' both in 4-byte
** and 8-byte alignments.
是一个联合体, 如果是使用 i_val 那就表示 Node 是一个普通的 TValue,
如果使用 u, 那么这个 Node 就保护了 Key 与 Vaule, 同时啊,
这个 Key 也有类型(key_tt)与值(key_val), 值是类型(tt_)与值(value_),
还有一个 next 表示什么我再看看

还有啊, 因为这是一个联合体, 所以可以使用 i_val, 拿到值, 因为在 u, 前两个数据与TValue一致
*/
typedef union Node {
    struct NodeKey {
        TValuefields; /* fields for value */
        lu_byte key_tt; /* key type */
        int next; /* for chaining 相对于当前节点的偏移量*/
        Value key_val; /* key value */
    } u;
    TValue i_val; /* direct access to node's value as a proper 'TValue' */
} Node;

/* copy a value into a key, 把 obj 的类型给 key 的类型, 把 obj 的值给 key 的值  */
#define setnodekey(L, node, obj)                                                                                                                                                                       \
    {                                                                                                                                                                                                  \
        Node* n_ = (node);                                                                                                                                                                             \
        const TValue* io_ = (obj);                                                                                                                                                                     \
        n_->u.key_val = io_->value_;                                                                                                                                                                   \
        n_->u.key_tt = io_->tt_;                                                                                                                                                                       \
        checkliveness(L, io_);                                                                                                                                                                         \
    }

/* copy a value from a key */
#define getnodekey(L, obj, node)                                                                                                                                                                       \
    {                                                                                                                                                                                                  \
        TValue* io_ = (obj);                                                                                                                                                                           \
        const Node* n_ = (node);                                                                                                                                                                       \
        io_->value_ = n_->u.key_val;                                                                                                                                                                   \
        io_->tt_ = n_->u.key_tt;                                                                                                                                                                       \
        checkliveness(L, io_);                                                                                                                                                                         \
    }

/*
** About 'alimit': if 'isrealasize(t)' is true, then 'alimit' is the
** real size of 'array'. Otherwise, the real size of 'array' is the
** smallest power of two not smaller than 'alimit' (or zero iff 'alimit'
** is zero); 'alimit' is then used as a hint for #t.
*/

#define BITRAS (1 << 7)
#define isrealasize(t) (!((t)->flags & BITRAS))
#define setrealasize(t) ((t)->flags &= cast_byte(~BITRAS))
#define setnorealasize(t) ((t)->flags |= BITRAS)

/// @brief Lua 的 表 结构
typedef struct Table {
    CommonHeader; // 一个指向 GCObject 的指针,用于垃圾回收
    lu_byte flags; /* 1<<p means tagmethod(p) is not present  用于标识表是否有某些特殊的属性,例如是否需要调用元方法、是否为弱表等等*/
    lu_byte lsizenode; /* log2 of size of 'node' array 哈希表的大小, 由于哈希表的大小一定为 2 的整数次幂, 所以这里表示的是幂次, 而不是实际大小 . node 数组的大小为 2^lsizenode */
    unsigned int alimit; /* "limit" of 'array' array 数组部分的大小.array[0] 至 array[alimit-1] 表示数组部分 */
    TValue* array; /* array part */
    Node* node; // 哈希表
    Node* lastfree; /* any free position is before this position  指向 Node 数组中的一个空闲位置,用于快速分配新的节点*/
    struct Table* metatable;
    GCObject* gclist; // 用于垃圾回收,指向下一个需要回收的对象
} Table;

/*
** Macros to manipulate keys inserted in nodes
*/
#define keytt(node) ((node)->u.key_tt)
#define keyval(node) ((node)->u.key_val)

#define keyisnil(node) (keytt(node) == LUA_TNIL)
#define keyisinteger(node) (keytt(node) == LUA_VNUMINT)
#define keyival(node) (keyval(node).i)
#define keyisshrstr(node) (keytt(node) == ctb(LUA_VSHRSTR))
#define keystrval(node) (gco2ts(keyval(node).gc))

#define setnilkey(node) (keytt(node) = LUA_TNIL)

#define keyiscollectable(n) (keytt(n) & BIT_ISCOLLECTABLE)

#define gckey(n) (keyval(n).gc)
#define gckeyN(n) (keyiscollectable(n) ? gckey(n) : NULL)

/*
** Dead keys in tables have the tag DEADKEY but keep their original
** gcvalue. This distinguishes them from regular keys but allows them to
** be found when searched in a special way. ('next' needs that to find
** keys removed from a table during a traversal.)
*/
#define setdeadkey(node) (keytt(node) = LUA_TDEADKEY)
#define keyisdead(node) (keytt(node) == LUA_TDEADKEY)

/* }================================================================== */

// s 对 size 的余数, 这里由于 size 是 2 的幂次, 所以可以使用 size - 1 与 s 做按位与来快速求余数; 'module' operation for hashing (size is always a power of 2)
#define lmod(s, size) (check_exp((size & (size - 1)) == 0, (cast_int((s) & ((size)-1)))))
// 生成一个 2 的 x 幂的数
#define twoto(x) (1 << (x))
// 一个表的 hash 部分的大小( 2 的 lsizenode 次)
#define sizenode(t) (twoto((t)->lsizenode))

/* size of buffer for 'luaO_utf8esc' function */
#define UTF8BUFFSZ 8

LUAI_FUNC int luaO_utf8esc(char* buff, unsigned long x);
LUAI_FUNC int luaO_ceillog2(unsigned int x);
LUAI_FUNC int luaO_rawarith(lua_State* L, int op, const TValue* p1, const TValue* p2, TValue* res);
LUAI_FUNC void luaO_arith(lua_State* L, int op, const TValue* p1, const TValue* p2, StkId res);
LUAI_FUNC size_t luaO_str2num(const char* s, TValue* o);
LUAI_FUNC int luaO_hexavalue(int c);
LUAI_FUNC void luaO_tostring(lua_State* L, TValue* obj);
LUAI_FUNC const char* luaO_pushvfstring(lua_State* L, const char* fmt, va_list argp);
LUAI_FUNC const char* luaO_pushfstring(lua_State* L, const char* fmt, ...);
LUAI_FUNC void luaO_chunkid(char* out, const char* source, size_t srclen);

#endif
