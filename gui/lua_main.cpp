#include "lua_main.h"

lua_main::lua_main(std::string lua_file)
{
    this->L = luaL_newstate();
    luaL_openlibs(L);
    luaL_dofile(L, lua_file.c_str());
}

lua_main::~lua_main()
{
    lua_close(L);
}

void lua_main::update()
{
    if (this->L != nullptr)
    {
        lua_getglobal(L, "update");
        lua_pcall(this->L, 0, 0, 0);
    }
}
