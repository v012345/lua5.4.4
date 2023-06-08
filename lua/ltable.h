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
// 直接在 hash 部分找键值为 key 的 Node, 如果在返回 Node 的 i_val, 否则返回 &absentkey
LUAI_FUNC const TValue* luaH_getshortstr(Table* t, TString* key);
// key 为短串直接调用 luaH_getshortstr, 长串的话,调用 getgeneric
LUAI_FUNC const TValue* luaH_getstr(Table* t, TString* key);
// 通过 get 方法, 根据 key 的类型调用 luaH_getint, luaH_getshortstr 或 getgeneric
LUAI_FUNC const TValue* luaH_get(Table* t, const TValue* key);
// 当有新的 key 时, key 对应不上数组部分, 就调用 luaH_newkey 放到 hash 部分中
LUAI_FUNC void luaH_newkey(lua_State* L, Table* t, const TValue* key, TValue* value);
// 调用 luaH_get 拿到 key 对应的 TValue* v, 使用 luaH_finishset 对 key value v 进行设置
LUAI_FUNC void luaH_set(lua_State* L, Table* t, const TValue* key, TValue* value);
// slot 就是通过 get 方法拿到的 key 对应的 v, 如果 v 为 &absentkey, 调用 luaH_newkey, 不然直接把 value 赋值给 slot
LUAI_FUNC void luaH_finishset(lua_State* L, Table* t, const TValue* key, const TValue* slot, TValue* value);
// 生成一个 hash 大小为 0, 没有数组部分, 没有元表的表
LUAI_FUNC Table* luaH_new(lua_State* L);
// 给 t 缩放大小, 包括数组与 hash 部分, 同时把 t 的数组部分边界扩至最大,即 nasize
LUAI_FUNC void luaH_resize(lua_State* L, Table* t, unsigned int nasize, unsigned int nhsize);
// hash 部分大小不变, 只缩放数组部分至 nasize, 同时把 t 的数组部分边界扩至最大,即 nasize
LUAI_FUNC void luaH_resizearray(lua_State* L, Table* t, unsigned int nasize);
// 释放 hash 部分, 释放数组部分, 最后释放表本身
LUAI_FUNC void luaH_free(lua_State* L, Table* t);
// 一个迭代器, 如果 key 为空就是第一次, 之后会根据 key 的值来把 key 的下一个 key-value 对写到 key 与 top 中, 如果已经到最后了, 就返回 0
LUAI_FUNC int luaH_next(lua_State* L, Table* t, StkId key);
//
LUAI_FUNC lua_Unsigned luaH_getn(Table* t);
// 返回数组部分的实际大小
LUAI_FUNC unsigned int luaH_realasize(const Table* t);

#if defined(LUA_DEBUG)
LUAI_FUNC Node* luaH_mainposition(const Table* t, const TValue* key);
#endif

#endif
