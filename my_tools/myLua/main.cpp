#include <lua.hpp>
extern "C" {
#include <lfs.h>
#include <lno.h>
#include <lobject.h>
#include <lstate.h>
}
#define LUA_MAIN_SCRIPT "./main.lua"
#define LUA_CODE_SCRIPT "./bytedump.lua"
int main(int argc, char const* argv[]) {
    lua_State* L = luaL_newstate();
    luaL_openlibs(L);
    luaopen_lfs(L);
    luaL_dofile(L, LUA_MAIN_SCRIPT);
    return 0;
    // lua_State* L = luaL_newstate();
    // luaL_loadfile(L, LUA_MAIN_SCRIPT);
    // TValue* tv = s2v(L->top.p - 1);
    // if (ttype(tv) != 6) { return 0; }
    // LClosure* LC = clLvalue(tv);
    // Proto* p = LC->p;
    // lua_State* L1 = luaL_newstate();
    // luaL_openlibs(L1);
    // luaopen_lfs(L1);
    // luaL_dofile(L1, LUA_CODE_SCRIPT);
    // lua_getglobal(L1, "Bytedump");
    // lua_getfield(L1, -1, "dump");
    // lua_pushvalue(L1, -2);
    // lua_newtable(L1);
    // lua_pushstring(L1, "instructions");
    // lua_newtable(L1);
    // for (size_t i = 0; i < p->sizecode; i++) {
    //     lua_pushinteger(L1, i + 1);
    //     lua_pushinteger(L1, p->code[i]);
    //     lua_settable(L1, -3);
    // }
    // lua_settable(L1, -3);
    // lua_pushstring(L1, "script_name");
    // lua_pushstring(L1, LUA_MAIN_SCRIPT);
    // lua_settable(L1, -3);
    // lua_pcall(L1, 2, 0, 0);
    // luaL_dofile(L1, LUA_MAIN_SCRIPT);
    // return 0;
}