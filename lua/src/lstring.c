/*
** $Id: lstring.c $
** String table (keeps all strings handled by Lua)
** See Copyright Notice in lua.h
** 字符串池
*/

#define lstring_c
#define LUA_CORE

#include "lprefix.h"

#include <string.h>

#include "lua.h"

#include "ldebug.h"
#include "ldo.h"
#include "lmem.h"
#include "lobject.h"
#include "lstate.h"
#include "lstring.h"

/*
** Maximum size for string table.
*/
#define MAXSTRTB cast_int(luaM_limitN(MAX_INT, TString*))

/**
 * @brief equality for long strings
 * 长字符串比较
 * 1.比是不是同一个串
 * 2.长度等不等
 * 3.内容比较
 * @param a
 * @param b
 * @return int
 */
int luaS_eqlngstr(TString* a, TString* b) {
    size_t len = a->u.lnglen;
    lua_assert(a->tt == LUA_VLNGSTR && b->tt == LUA_VLNGSTR);
    return (a == b) || /* same instance or... */
           ((len == b->u.lnglen) && /* equal length and ... */
            (memcmp(getstr(a), getstr(b), len) == 0)); /* equal contents */
}

/// @brief 计算字符串哈希值, 使用 djb2 算法
/// @param str 字符串
/// @param l 字符串长度
/// @param seed 随机数
/// @return unsigned int
unsigned int luaS_hash(const char* str, size_t l, unsigned int seed) {
    unsigned int h = seed ^ cast_uint(l);
    for (; l > 0; l--) h ^= ((h << 5) + (h >> 2) + cast_byte(str[l - 1]));
    return h;
}

unsigned int luaS_hashlongstr(TString* ts) {
    lua_assert(ts->tt == LUA_VLNGSTR);
    if (ts->extra == 0) { /* no hash? */
        size_t len = ts->u.lnglen;
        ts->hash = luaS_hash(getstr(ts), len, ts->hash);
        ts->extra = 1; /* now it has its hash */
    }
    return ts->hash;
}

static void tablerehash(TString** vect, int osize, int nsize) {
    int i;
    // 如果要扩大, 那么新申请来的空间初始化一下
    for (i = osize; i < nsize; i++) /* clear new elements */
        vect[i] = NULL;
    // 把原来数据重新分发来各自的桶里
    for (i = 0; i < osize; i++) { /* rehash old part of the array */
        TString* p = vect[i]; // 用 p 指向各个桶
        // 把当前桶清空
        vect[i] = NULL;
        // 遍历这个桶
        while (p) { /* for each string in the list */
            // 保存 p 的后继指针
            TString* hnext = p->u.hnext; /* save next */
            // 计算出新的桶的位置
            unsigned int h = lmod(p->hash, nsize); /* new position */
            // 把新桶也连到 p 后面
            p->u.hnext = vect[h]; /* chain it into array  */
            // 使用新桶的第一个元素为 p
            vect[h] = p;
            // 下一个元素开始
            p = hnext;
        }
    }
}

/*
** Resize the string table. If allocation fails, keep the current size.
** (This can degrade performance, but any non-zero size should work
** correctly.)
** 调用 tablerehash, 这调用之前, 要注意内存的分配
*/
void luaS_resize(lua_State* L, int nsize) {
    stringtable* tb = &G(L)->strt;
    int osize = tb->size;
    TString** newvect;
    if (nsize < osize) /* shrinking table? */
        tablerehash(tb->hash, osize, nsize); /* depopulate shrinking part */
    newvect = luaM_reallocvector(L, tb->hash, osize, nsize, TString*);
    if (l_unlikely(newvect == NULL)) { /* reallocation failed? */
        if (nsize < osize) /* was it shrinking table? */
            tablerehash(tb->hash, nsize, osize); /* restore to original size */
        /* leave table as it was */
    } else { /* allocation succeeded */
        tb->hash = newvect;
        tb->size = nsize;
        if (nsize > osize) tablerehash(newvect, osize, nsize); /* rehash for new size */
    }
}

/*
** Clear API string cache. (Entries cannot be empty, so fill them with
** a non-collectable string.)
*/
void luaS_clearcache(global_State* g) {
    int i, j;
    for (i = 0; i < STRCACHE_N; i++)
        for (j = 0; j < STRCACHE_M; j++) {
            if (iswhite(g->strcache[i][j])) /* will entry be collected? */
                g->strcache[i][j] = g->memerrmsg; /* replace it with something fixed */
        }
}

/*
** Initialize the string table and the string cache
*/
void luaS_init(lua_State* L) {
    global_State* g = G(L);
    int i, j;
    stringtable* tb = &G(L)->strt;
    tb->hash = luaM_newvector(L, MINSTRTABSIZE, TString*); // 初始化哈希桶大小为 MINSTRTABSIZE = 128
    tablerehash(tb->hash, 0, MINSTRTABSIZE); /* 把上一步申请来内存置NULL ; clear array */
    tb->size = MINSTRTABSIZE; // 显式指出哈希桶的大小
    g->memerrmsg = luaS_newliteral(L, MEMERRMSG); /* pre-create memory-error message */
    luaC_fix(L, obj2gco(g->memerrmsg)); /* it should never be collected */
    for (i = 0; i < STRCACHE_N; i++) /* fill cache with valid strings */
        for (j = 0; j < STRCACHE_M; j++) g->strcache[i][j] = g->memerrmsg; // 临时初始化一下, 之后会改的
}

/*
** creates a new string object
*/
static TString* createstrobj(lua_State* L, size_t l, int tag, unsigned int h) {
    TString* ts;
    GCObject* o;
    size_t totalsize; /* total size of TString object */
    totalsize = sizelstring(l);
    o = luaC_newobj(L, tag, totalsize);
    ts = gco2ts(o);
    ts->hash = h;
    ts->extra = 0;
    getstr(ts)[l] = '\0'; /* ending 0 */
    return ts;
}

TString* luaS_createlngstrobj(lua_State* L, size_t l) {
    TString* ts = createstrobj(L, l, LUA_VLNGSTR, G(L)->seed);
    ts->u.lnglen = l;
    return ts;
}

void luaS_remove(lua_State* L, TString* ts) {
    stringtable* tb = &G(L)->strt;
    TString** p = &tb->hash[lmod(ts->hash, tb->size)];
    while (*p != ts) /* find previous element */
        p = &(*p)->u.hnext;
    *p = (*p)->u.hnext; /* remove element from its list */
    tb->nuse--;
}

/// @brief 如果有空间, 那么就把 字符串 表的大小 扩大 两倍, 并重新排列所有字符串的位置
/// @param L
/// @param tb
static void growstrtab(lua_State* L, stringtable* tb) {
    if (l_unlikely(tb->nuse == MAX_INT)) { /* too many strings? */
        luaC_fullgc(L, 1); /* try to free some... */
        if (tb->nuse == MAX_INT) /* still too many? */
            luaM_error(L); /* cannot even create a message... */
    }
    if (tb->size <= MAXSTRTB / 2) /* can grow string table? */
        luaS_resize(L, tb->size * 2);
}

/*
** Checks whether short string exists and reuses it or creates a new one.
** 内部化短字符串, 先看哈希桶里有没有 str, 有直接返回, 没有就新创建一个放到桶里
*/
static TString* internshrstr(lua_State* L, const char* str, size_t l) {
    TString* ts;
    global_State* g = G(L);
    stringtable* tb = &g->strt; // 全局字符串 hash 表
    unsigned int h = luaS_hash(str, l, g->seed); // 算出短串的 hash 值
    TString** list = &tb->hash[lmod(h, tb->size)]; // 定位到 hash 值所在的哈希桶的地址的指针
    lua_assert(str != NULL); /* otherwise 'memcmp'/'memcpy' are undefined */

    // 在当前桶中遍历, 看是否已经存在, 如果存在就返回这个 TString 的地址
    for (ts = *list; ts != NULL; ts = ts->u.hnext) {
        if (l == ts->shrlen && (memcmp(str, getstr(ts), l * sizeof(char)) == 0)) {
            /* found! */
            if (isdead(g, ts)) /* dead (but not collected yet)? */
                changewhite(ts); /* resurrect it */
            return ts;
        }
    }
    // 到这里说明没有找到

    /* else must create a new string */
    if (tb->nuse >= tb->size) { /* need to grow string table? */
        growstrtab(L, tb);
        list = &tb->hash[lmod(h, tb->size)]; /* rehash with new size */
    }
    ts = createstrobj(L, l, LUA_VSHRSTR, h);
    memcpy(getstr(ts), str, l * sizeof(char));
    ts->shrlen = cast_byte(l);
    ts->u.hnext = *list;
    *list = ts;
    tb->nuse++;
    return ts;
}

/// @brief 生成 TString \r
/// new string (with explicit length)
/// @param l str 的长度
TString* luaS_newlstr(lua_State* L, const char* str, size_t l) {
    if (l <= LUAI_MAXSHORTLEN) /* short string? */
        return internshrstr(L, str, l);
    else {
        TString* ts;
        if (l_unlikely(l >= (MAX_SIZE - sizeof(TString)) / sizeof(char))) luaM_toobig(L);
        ts = luaS_createlngstrobj(L, l);
        memcpy(getstr(ts), str, l * sizeof(char));
        return ts;
    }
}

/*
** Create or reuse a zero-terminated string, first checking in the
** cache (using the string address as a key). The cache can contain
** only zero-terminated strings, so it is safe to use 'strcmp' to
** check hits.
*/
TString* luaS_new(lua_State* L, const char* str) {
    unsigned int i = point2uint(str) % STRCACHE_N; /* hash */
    int j;
    TString** p = G(L)->strcache[i];
    for (j = 0; j < STRCACHE_M; j++) {
        if (strcmp(str, getstr(p[j])) == 0) /* hit? */
            return p[j]; /* that is it */
    }
    /* normal route */
    for (j = STRCACHE_M - 1; j > 0; j--) p[j] = p[j - 1]; /* move out last element */
    /* new element is first in the list */
    p[0] = luaS_newlstr(L, str, strlen(str));
    return p[0];
}

/// @brief Userdata 的构造函数
/// @param L
/// @param s
/// @param nuvalue
/// @return
Udata* luaS_newudata(lua_State* L, size_t s, int nuvalue) {
    Udata* u;
    int i;
    GCObject* o;
    if (l_unlikely(s > MAX_SIZE - udatamemoffset(nuvalue))) luaM_toobig(L);
    o = luaC_newobj(L, LUA_VUSERDATA, sizeudata(nuvalue, s));
    u = gco2u(o);
    u->len = s;
    u->nuvalue = nuvalue;
    u->metatable = NULL;
    for (i = 0; i < nuvalue; i++) setnilvalue(&u->uv[i].uv);
    return u;
}
