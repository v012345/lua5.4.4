#include <lua.hpp>
extern "C" {
#include <lfs.h>
#include <lgc.h>
#include <lno.h>
#include <lobject.h>
#include <lstate.h>
}
#define LUA_MAIN_SCRIPT "./main.lua"
#define LUA_CODE_SCRIPT "./bytedump.lua"
static int C_CompileFile(lua_State* L);
int main(int argc, char const* argv[]) {
    lua_State* L = luaL_newstate();
    luaL_openlibs(L);
    luaopen_lfs(L);
    lua_register(L, "Compile", C_CompileFile);
    luaL_dofile(L, LUA_MAIN_SCRIPT);
    return 0;
}

static int C_CompileFile(lua_State* L) {
    const char* file = lua_tostring(L, 1);
    luaL_loadfile(L, file);
    TValue* tv = s2v(L->top.p - 1);
    // if (ttype(tv) != 6) { return 0; }

    LClosure* LC = clLvalue(tv);
    Proto* p = LC->p;

    lua_newtable(L);
    lua_pushstring(L, "instructions");
    lua_newtable(L);
    for (size_t i = 0; i < p->sizecode; i++) {
        lua_pushinteger(L, i + 1);
        lua_pushinteger(L, p->code[i]);
        lua_settable(L, -3);
    }
    lua_settable(L, -3);
    // while (/* condition */)
    // {
    //     /* code */
    // }
    
    // lua_pushstring(L1, "script_name");
    // lua_pushstring(L1, LUA_MAIN_SCRIPT);
    // lua_settable(L1, -3);
    return 1;
}