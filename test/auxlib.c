#include "auxlib.h"
int luaopen_aux(lua_State* L, int argc, char const* argv[]) {
    lua_newtable(L);
    for (int i = 0; i < argc; i++) {
        lua_pushstring(L, argv[i]);
        lua_pushboolean(L, 1);
        lua_settable(L, -3);
    }
    lua_setglobal(L, "arg");
    luaL_dofile(L, LUA_AUX_LIB);
    return 1;
}
int aux_print_wchar(lua_State* L, const wchar_t wc) {
    lua_getglobal(L, "Global");
    lua_getfield(L, -1, "wchar_to_utf8");
    lua_newtable(L);
    lua_pushinteger(L, 1);
    lua_pushinteger(L, wc);
    lua_settable(L, -3);
    lua_pcall(L, 1, 0, 0);
    return 1;
}
int aux_print_wstring(lua_State* L, const wchar_t* ws, size_t size) {
    lua_getglobal(L, "Global");
    lua_getfield(L, -1, "wchar_to_utf8");
    lua_newtable(L);
    int count = size / sizeof(wchar_t);
    for (size_t i = 0; i < count; i++) { /* code */
        lua_pushinteger(L, i + 1);
        lua_pushinteger(L, ws[i]);
        lua_settable(L, -3);
    }
    // lua_pushinteger(L, count);
    lua_pcall(L, 1, 0, 0);
    return 1;
}