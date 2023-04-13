/*
** $Id: lstring.c $
** String table (keeps all strings handled by Lua)
** See Copyright Notice in lua.h
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

// Maximum size for string table.
#define MAXSTRTB cast_int(luaM_limitN(MAX_INT, TString*))

/// @brief 比较长字符串是否相等 \r
/// equality for long strings
int luaS_eqlngstr(TString* a, TString* b) {
    size_t len = a->u.lnglen;
    lua_assert(a->tt == LUA_VLNGSTR && b->tt == LUA_VLNGSTR);
    return (a == b) || /* same instance or... */
           ((len == b->u.lnglen) && /* equal length and ... */
            (memcmp(getstr(a), getstr(b), len) == 0)); /* equal contents */
}

/// @brief 计算字符串哈希值
unsigned int luaS_hash(const char* str, size_t l, unsigned int seed) {
    unsigned int h = seed ^ cast_uint(l);
    for (; l > 0; l--) h ^= ((h << 5) + (h >> 2) + cast_byte(str[l - 1]));
    return h;
}

/// @brief 获取长字符串的 hash
unsigned int luaS_hashlongstr(TString* ts) {
    lua_assert(ts->tt == LUA_VLNGSTR);
    if (ts->extra == 0) { /* no hash? */
        size_t len = ts->u.lnglen;
        // 在 TString 初始化时, hash 会被赋值为 g->seed
        ts->hash = luaS_hash(getstr(ts), len, ts->hash);
        ts->extra = 1; /* now it has its hash */
    }
    return ts->hash;
}

/// @brief 重新排列 vect 表
/// @param osize 原始大小
/// @param nsize 新大小
static void tablerehash(TString** vect, int osize, int nsize) {
    int i;
    for (i = osize; i < nsize; i++) /* clear new elements */
        vect[i] = NULL;
    for (i = 0; i < osize; i++) { /* rehash old part of the array */
        TString* p = vect[i];
        vect[i] = NULL;
        while (p) { /* for each string in the list */
            TString* hnext = p->u.hnext; /* save next */
            unsigned int h = lmod(p->hash, nsize); /* new position */
            p->u.hnext = vect[h]; /* chain it into array  */
            vect[h] = p;
            p = hnext;
        }
    }
}

/// @brief 调整字符哈希表的大小 \r
/// Resize the string table. If allocation fails, keep the current size.
/// (This can degrade performance, but any non-zero size should work correctly.)
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

/// @brief Clear API string cache. (Entries cannot be empty, so fill them with a non-collectable string.)
void luaS_clearcache(global_State* g) {
    int i, j;
    for (i = 0; i < STRCACHE_N; i++)
        for (j = 0; j < STRCACHE_M; j++) {
            if (iswhite(g->strcache[i][j])) /* will entry be collected? */
                g->strcache[i][j] = g->memerrmsg; /* replace it with something fixed */
        }
}

/// @brief Initialize the string table and the string cache
void luaS_init(lua_State* L) {
    global_State* g = G(L);
    int i, j;
    stringtable* tb = &G(L)->strt;
    tb->hash = luaM_newvector(L, MINSTRTABSIZE, TString*);
    tablerehash(tb->hash, 0, MINSTRTABSIZE); /* clear array */
    tb->size = MINSTRTABSIZE; // 显式指出哈希桶的大小
    g->memerrmsg = luaS_newliteral(L, MEMERRMSG); /* pre-create memory-error message */
    luaC_fix(L, obj2gco(g->memerrmsg)); /* it should never be collected */
    for (i = 0; i < STRCACHE_N; i++) /* fill cache with valid strings */
        for (j = 0; j < STRCACHE_M; j++) g->strcache[i][j] = g->memerrmsg;
}

/// @brief 生成一个 TString 对象, 没有内容
/// creates a new string object
/// @param l 字符串长度
/// @param tag 子类型, 长还是短
/// @param h 哈希值
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

/// @brief 生成一个长字符串 TString
TString* luaS_createlngstrobj(lua_State* L, size_t l) {
    TString* ts = createstrobj(L, l, LUA_VLNGSTR, G(L)->seed);
    ts->u.lnglen = l;
    return ts;
}

/// @brief 从字符串哈希表中移除 ts
void luaS_remove(lua_State* L, TString* ts) {
    stringtable* tb = &G(L)->strt;
    TString** p = &tb->hash[lmod(ts->hash, tb->size)];
    while (*p != ts) /* find previous element */
        p = &(*p)->u.hnext;
    *p = (*p)->u.hnext; /* remove element from its list */
    tb->nuse--;
}

/// @brief 如果 tb 的大小小于 MAXSTRTB, tb 扩大两倍, 并重新排列
static void growstrtab(lua_State* L, stringtable* tb) {
    if (l_unlikely(tb->nuse == MAX_INT)) { /* too many strings? */
        luaC_fullgc(L, 1); /* try to free some... */
        if (tb->nuse == MAX_INT) /* still too many? */
            luaM_error(L); /* cannot even create a message... */
    }
    if (tb->size <= MAXSTRTB / 2) /* can grow string table? */
        luaS_resize(L, tb->size * 2);
}

/// @brief Checks whether short string exists and reuses it or creates a new one.
static TString* internshrstr(lua_State* L, const char* str, size_t l) {
    TString* ts;
    global_State* g = G(L);
    stringtable* tb = &g->strt; // 字符串 hash 表
    unsigned int h = luaS_hash(str, l, g->seed);
    TString** list = &tb->hash[lmod(h, tb->size)];
    lua_assert(str != NULL); /* otherwise 'memcmp'/'memcpy' are undefined */
    for (ts = *list; ts != NULL; ts = ts->u.hnext) {
        if (l == ts->shrlen && (memcmp(str, getstr(ts), l * sizeof(char)) == 0)) { /* found! */
            if (isdead(g, ts)) /* dead (but not collected yet)? */
                changewhite(ts); /* resurrect it */
            return ts;
        }
    }
    /* else must create a new string */
    if (tb->nuse >= tb->size) { /* need to grow string table? */
        // 如果已经不能扩大了, 就不扩大了, 就将就着用吧, 但是如果实在是存了大多了, 会报错的
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

/// @brief 生成 TString 对象 \r
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

/// @brief 相当于全部 TString 对象的二缓 \r
/// Create or reuse a zero-terminated string, first checking in the
/// cache (using the string address as a key). The cache can contain
/// only zero-terminated strings, so it is safe to use 'strcmp' to
/// check hits.
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
/// @param s
/// @param nuvalue
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
