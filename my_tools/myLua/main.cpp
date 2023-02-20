#include <lua.hpp>
#include <filesystem>
#include "nightowl_c_api.h"
#include "XML.hpp"
#define LUA_MAIN_SCRIPT "./main.lua"
int main(int argc, char const *argv[])
{

    lua_State *L = luaL_newstate();
    luaL_openlibs(L);
    lua_newtable(L);
    for (size_t i = 0; i < argc; i++)
    {
        std::cout << argv[i] << std::endl;
        if (std::string("-b").compare(argv[i]) == 0)
        {
            lua_pushstring(L, "branch");
            lua_pushstring(L, argv[i + 1]);
            lua_settable(L, -3);
        }
        else if (std::string("-m").compare(argv[i]) == 0)
        {
            lua_pushstring(L, "module");
            lua_pushstring(L, argv[i + 1]);
            lua_settable(L, -3);
        }
        else if (std::string("-f").compare(argv[i]) == 0)
        {
            lua_pushstring(L, "from");
            lua_pushstring(L, argv[i + 1]);
            lua_settable(L, -3);
        }
        else if (std::string("-t").compare(argv[i]) == 0)
        {
            lua_pushstring(L, "to");
            lua_pushstring(L, argv[i + 1]);
            lua_settable(L, -3);
        }
    }
    lua_setglobal(L, "argv");
    if (std::filesystem::exists(LUA_MAIN_SCRIPT))
    {
        NIGHTOWL::C_API(L);
        NIGHTOWL::LUA_REGISTER_CPP_CLASS(L);
        luaL_dofile(L, LUA_MAIN_SCRIPT);
    }
    return 0;
}
