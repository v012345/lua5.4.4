#include "angel.hpp"
angel::angel(/* args */) {}

angel::~angel() {}
int angel::getName(lua_State* L) {
    if (this->name != NULL) {
        lua_pushstring(L, this->name.c_str());
        /* code */
    } else {
        lua_pushstring(L, "NULL");
    }
    return 1;
}

static void angel::REGISTER() {}

static int angel::lua_new(lua_State* L) {
    // MyClass* obj = new MyClass();
    // MyClass** lua_obj = (MyClass**)lua_newuserdata(L, sizeof(MyClass*));
    // *lua_obj = obj;
    // luaL_getmetatable(L, "MyClass");
    // lua_setmetatable(L, -2);
    return 1;
}

static int angel::lua_getName(lua_State* L) { return 1; }