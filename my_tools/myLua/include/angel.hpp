#pragma once
#include <lua.hpp>
#include <string>
class angel {
  private:
    std::string name = NULL;
    /* data */
  public:
    angel(/* args */);
    ~angel();
    int getName(lua_State* L);
    static void REGISTER();
    static int lua_new(lua_State* L);
    static int lua_getName(lua_State* L);
    static const luaL_Reg LIBS[] = {
        {"getName", angel::lua_getName},
        {NULL, NULL},
    };
};
