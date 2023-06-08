/*
** $Id: ltable.h $
** Lua tables (hash)
** See Copyright Notice in lua.h
*/

#ifndef ltable_h
#define ltable_h

#include "lobject.h"

#define gnode(t, i) (&(t)->node[i]) // get node[i], 拿到表索引为 i 的 Node
#define gval(n) (&(n)->i_val) // get value, 拿的 Node 里保存的值 TValue
#define gnext(n) ((n)->u.next) // get next 值, 即相对于当前 Node 下一个 Node 的偏移量

/*
** Clear all bits of fast-access metamethods, which means that the table
** may have any of these metamethods. (First access that fails after the
** clearing will set the bit again.)
*/
#define invalidateTMcache(t) ((t)->flags &= ~maskflags) // 把表的 flags 的有没元表缓存清空(低 6 位置 0)

/* true when 't' is using 'dummynode' as its hash part */
#define isdummy(t) ((t)->lastfree == NULL) // 看看表 t 没有没真正的 hash 部分

/* allocated size for hash nodes */
#define allocsizenode(t) (isdummy(t) ? 0 : sizenode(t)) // 返回表 t 的 hash 部分 Node 的数量

/* returns the Node, given the value of a table entry */
#define nodefromval(v) cast(Node*, (v)) // Node 里的 i_val 的 TValue* 转回 Node*

// 如果 key 在数组部分, 返回数组部分的 TValue*, 否则去 hash 部分查找, 如果存在 key, 返回 Node 的 i_val, 没有返回 &absentkey
LUAI_FUNC const TValue* luaH_getint(Table* t, lua_Integer key);
// 先通过 luaH_getint 拿到 key 对应的 TValue* v, 如果 v 是 &absentkey, 就调用 luaH_newkey, 否则直接把 value 赋值给 v
LUAI_FUNC void luaH_setint(lua_State* L, Table* t, lua_Integer key, TValue* value);
LUAI_FUNC const TValue* luaH_getshortstr(Table* t, TString* key);
LUAI_FUNC const TValue* luaH_getstr(Table* t, TString* key);
LUAI_FUNC const TValue* luaH_get(Table* t, const TValue* key);
LUAI_FUNC void luaH_newkey(lua_State* L, Table* t, const TValue* key, TValue* value);
LUAI_FUNC void luaH_set(lua_State* L, Table* t, const TValue* key, TValue* value);
LUAI_FUNC void luaH_finishset(lua_State* L, Table* t, const TValue* key, const TValue* slot, TValue* value);
LUAI_FUNC Table* luaH_new(lua_State* L);
LUAI_FUNC void luaH_resize(lua_State* L, Table* t, unsigned int nasize, unsigned int nhsize);
LUAI_FUNC void luaH_resizearray(lua_State* L, Table* t, unsigned int nasize);
LUAI_FUNC void luaH_free(lua_State* L, Table* t);
LUAI_FUNC int luaH_next(lua_State* L, Table* t, StkId key);
LUAI_FUNC lua_Unsigned luaH_getn(Table* t);
LUAI_FUNC unsigned int luaH_realasize(const Table* t);

#if defined(LUA_DEBUG)
LUAI_FUNC Node* luaH_mainposition(const Table* t, const TValue* key);
#endif

#endif
