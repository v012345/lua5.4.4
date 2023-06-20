#include <lauxlib.h>
#include <lua.h>
#include <lualib.h>

#include "lno.h"
LNO_EXPORT int luaopen_lno(lua_State* L) {
    // dir_create_meta(L);
    // lock_create_meta(L);
    // new_lib(L, fslib);
    // lua_pushvalue(L, -1);
    // lua_setglobal(L, LFS_LIBNAME);
    // set_info(L);
    return 1;
}
