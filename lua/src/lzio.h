/*
** $Id: lzio.h $
** Buffered streams
** See Copyright Notice in lua.h
*/

#ifndef lzio_h
#define lzio_h

#include "lua.h"

#include "lmem.h"

#define EOZ (-1) /* end of stream */

/// @brief 用于读取数据源
/// @param n bytes still unread
/// @param p current position in buffer
/// @param reader reader function
/// @param data  additional data
/// @param L Lua state (for reader)
typedef struct Zio ZIO;

/// @brief 可以简单理解从文件中读入一个字符
#define zgetc(z) (((z)->n--) > 0 ? cast_uchar(*(z)->p++) : luaZ_fill(z))

/// @brief 主要在 save 中使用, 暂时存一个字符串
/// @param n buffer 中已存的字符个数
/// @param buffsize 申请来的 buffer 的长度
typedef struct Mbuffer {
    char *buffer;
    size_t n;
    size_t buffsize;
} Mbuffer;

#define luaZ_initbuffer(L, buff) ((buff)->buffer = NULL, (buff)->buffsize = 0)

#define luaZ_buffer(buff) ((buff)->buffer)
#define luaZ_sizebuffer(buff) ((buff)->buffsize)
#define luaZ_bufflen(buff) ((buff)->n)

#define luaZ_buffremove(buff, i) ((buff)->n -= (i))
// 把 buff 中已存的字符清空
#define luaZ_resetbuffer(buff) ((buff)->n = 0)

#define luaZ_resizebuffer(L, buff, size) ((buff)->buffer = luaM_reallocvchar(L, (buff)->buffer, (buff)->buffsize, size), (buff)->buffsize = size)

#define luaZ_freebuffer(L, buff) luaZ_resizebuffer(L, buff, 0)

LUAI_FUNC void luaZ_init(lua_State *L, ZIO *z, lua_Reader reader, void *data);
LUAI_FUNC size_t luaZ_read(ZIO *z, void *b, size_t n); /* read next n bytes */

/* --------- Private Part ------------------ */

/// @brief 用于读取数据源
/// @param n 还有多少字符没有读入
/// @param p
/// @param reader 用于读取数据源
/// @param data 是一个 LoadF, 就是读入的文件
/// @param L
struct Zio {
    size_t n;          /* bytes still unread */
    const char *p;     /* current position in buffer */
    lua_Reader reader; /* reader function */
    void *data;        /* additional data */
    lua_State *L;      /* Lua state (for reader) */
};

LUAI_FUNC int luaZ_fill(ZIO *z);

#endif
