#include <lua.hpp>
#include <filesystem>
#include "nightowl_c_api.h"
#include "nightowl_cpp_api.hpp"
#define LUA_MAIN_SCRIPT "./main.lua"
#define LUA_ARGV_SCRIPT "./argv.lua"
int main(int argc, char const *argv[])
{

    lua_State *L = luaL_newstate();
    luaL_openlibs(L);
    if (std::filesystem::exists(LUA_ARGV_SCRIPT))
    {
        luaL_dofile(L, LUA_ARGV_SCRIPT);
        lua_getglobal(L, "argv");
        for (size_t i = 0; i < argc; i++)
        {
            lua_pushinteger(L, i + 1);
            lua_pushstring(L, argv[i]);
            lua_settable(L, -3);
        }
        lua_getglobal(L, "ProcessArgv");
        lua_pcall(L, 0, 0, 0);
    }

    if (std::filesystem::exists(LUA_MAIN_SCRIPT))
    {
        NIGHTOWL::C_API(L);
        NIGHTOWL::REGISTER_LIBS_TO_LUA(L);
        luaL_dofile(L, LUA_MAIN_SCRIPT);
    }
    return 0;
}
