#include <lua.hpp>
#include <iostream>
int main(int argc, char const *argv[])
{
    std::cout << argv[1] << std::endl;
    lua_State *L = luaL_newstate();
    luaL_openlibs(L);
    return 0;
}
