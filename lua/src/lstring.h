/*
** $Id: lstring.h $
** String table (keep all strings handled by Lua)
** See Copyright Notice in lua.h
*/

#ifndef lstring_h
#define lstring_h

#include "lgc.h"
#include "lobject.h"
#include "lstate.h"

// Memory-allocation error message must be preallocated (it cannot be created after memory is exhausted)
#define MEMERRMSG "not enough memory"

// 长度为 l 的 lua 字符串所需的内存空间大小 \r
// Size of a TString: Size of the header plus space for the string itself (including final '\0').
#define sizelstring(l) (offsetof(TString, contents) + ((l) + 1) * sizeof(char))

// 用字面量(字符串常量) s 生成一个 TString, 最后的 -1 是为了去除 '\0' 的影响
#define luaS_newliteral(L, s) (luaS_newlstr(L, "" s, (sizeof(s) / sizeof(char)) - 1))

// 判断一个串是不是保留字 \r
// test whether a string is a reserved word
#define isreserved(s) ((s)->tt == LUA_VSHRSTR && (s)->extra > 0)

// 短字符串只有一份, 所以地址相等, 两个字符串就相等 \r
// equality for short strings, which are always internalized
#define eqshrstr(a, b) check_exp((a)->tt == LUA_VSHRSTR, (a) == (b))

LUAI_FUNC unsigned int luaS_hash(const char* str, size_t l, unsigned int seed);
LUAI_FUNC unsigned int luaS_hashlongstr(TString* ts);
LUAI_FUNC int luaS_eqlngstr(TString* a, TString* b);
LUAI_FUNC void luaS_resize(lua_State* L, int newsize);
LUAI_FUNC void luaS_clearcache(global_State* g);
LUAI_FUNC void luaS_init(lua_State* L);
LUAI_FUNC void luaS_remove(lua_State* L, TString* ts);
LUAI_FUNC Udata* luaS_newudata(lua_State* L, size_t s, int nuvalue);
LUAI_FUNC TString* luaS_newlstr(lua_State* L, const char* str, size_t l);
LUAI_FUNC TString* luaS_new(lua_State* L, const char* str);
LUAI_FUNC TString* luaS_createlngstrobj(lua_State* L, size_t l);

#endif
