#include <filesystem>
#include <lua.hpp>
extern "C" {
#include <lfs.h>
}
#define UNICODE
#include <windows.h>
#define LUA_MAIN_SCRIPT "./test.lua"
int main(int argc, char const* argv[]) {
    L = luaL_newstate();
    luaL_openlibs(L);
    luaopen_lfs(L);
    luaL_dofile(L, LUA_MAIN_SCRIPT); //
    return 0;
}
