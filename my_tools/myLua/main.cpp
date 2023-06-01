#include <filesystem>
#include <lua.hpp>
extern "C" {
#include <lfs.h>
}
#define LUA_MAIN_SCRIPT "./main.lua"
#define LUA_ARGV_SCRIPT "./bm_excel_to_lua.lua"

int main(int argc, char const* argv[]) {
    lua_State* L = luaL_newstate();
    luaL_openlibs(L);
    luaopen_lfs(L);
    if (std::filesystem::exists(LUA_ARGV_SCRIPT)) { //
        luaL_dofile(L, LUA_ARGV_SCRIPT);
    }
    return 0;
}
