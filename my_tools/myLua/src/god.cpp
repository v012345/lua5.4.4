#include "god.hpp"
god::god(/* args */) {}

god::~god() {}

int god::say(lua_State* L) {
    lua_pushstring(L, "1234");
    return 1;
}
