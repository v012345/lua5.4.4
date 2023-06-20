#include <lua.hpp>
extern "C" {
#include <lfs.h>
}
#define LUA_MAIN_SCRIPT "./test.lua"
void print_code(lua_State* L);
int main(int argc, char const* argv[]) {
    L = luaL_newstate();
    luaL_openlibs(L);
    luaopen_lfs(L);
    luaL_loadfile(L, LUA_MAIN_SCRIPT);
    lua_pcall(L, 0, LUA_MULTRET, 0);
    return 0;
}
void print_code(lua_State* L) {
    
}
