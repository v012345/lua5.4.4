#include <lua.hpp>
extern "C" {
#include <lfs.h>
#include <lno.h>
}
#define LUA_MAIN_SCRIPT "./test.lua"
int main(int argc, char const* argv[]) {
    lua_State* L = luaL_newstate();
    // luaL_openlibs(L);
    // luaopen_lfs(L);
    luaL_loadfile(L, LUA_MAIN_SCRIPT);
    lua_no_print_stack(L);
    lua_pcall(L, 0, LUA_MULTRET, 0);
    return 0;
}