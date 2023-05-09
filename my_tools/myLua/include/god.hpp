#pragma once
#include <lua.hpp>
class god {
  private:
    /* data */
  public:
    god(/* args */);
    ~god();
    int say(lua_State* L);
};
