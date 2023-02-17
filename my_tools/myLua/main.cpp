#include <lua.hpp>
#include <filesystem>
#define LUA_MAIN_SCRIPT "./lua/main.lua"
int main(int argc, char const *argv[])
{
    // if (std::string("-b").compare(argv[i]) == 0)
    // {
    //     lua_pushstring(L, "branch");
    //     lua_pushstring(L, argv[i + 1]);
    //     lua_settable(L, -3);
    // }

    // lua_setglobal(L, "argv");
    lua_State *L = luaL_newstate();
    luaL_openlibs(L);
    if (std::filesystem::exists(LUA_MAIN_SCRIPT))
    {
        luaL_dofile(L, LUA_MAIN_SCRIPT);
    }
    return 0;
}
