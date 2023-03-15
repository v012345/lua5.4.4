/*
** $Id: lzio.c $
** Buffered streams
** See Copyright Notice in lua.h
*/

#define lzio_c
#define LUA_CORE

#include "lprefix.h"

#include <string.h>

#include "lua.h"

#include "llimits.h"
#include "lmem.h"
#include "lstate.h"
#include "lzio.h"

/// @brief 从 LoadF 读一块 , 把读到的第一个字符放到 z->p , 所以 z->n = size - 1;
/// @param z
/// @return
int luaZ_fill(ZIO *z) {
    size_t size;
    lua_State *L = z->L;
    const char *buff;
    lua_unlock(L);
    buff = z->reader(L, z->data, &size);
    lua_lock(L);
    if (buff == NULL || size == 0) return EOZ;
    z->n = size - 1; /* discount char being returned */
    z->p = buff;
    return cast_uchar(*(z->p++));
}

/// @brief 对 ZIO 进行初始化
/// @param L
/// @param z
/// @param reader
/// @param data
void luaZ_init(lua_State *L, ZIO *z, lua_Reader reader, void *data) {
    z->L = L;
    z->reader = reader;
    z->data = data;
    z->n = 0;
    z->p = NULL;
}

/* --------------------------------------------------------------- read --- */
size_t luaZ_read(ZIO *z, void *b, size_t n) {
    while (n) {
        size_t m;
        if (z->n == 0) {             /* no bytes in buffer? */
            if (luaZ_fill(z) == EOZ) /* try to read more */
                return n;            /* no more input; return number of missing bytes */
            else {
                z->n++; /* luaZ_fill consumed first byte; put it back */
                z->p--;
            }
        }
        m = (n <= z->n) ? n : z->n; /* min. between n and z->n */
        memcpy(b, z->p, m);
        z->n -= m;
        z->p += m;
        b = (char *)b + m;
        n -= m;
    }
    return 0;
}
