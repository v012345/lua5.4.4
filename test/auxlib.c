#include "auxlib.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
int luaopen_aux(lua_State* L, int argc, char const* argv[]) {
    lua_newtable(L);
    for (int i = 0; i < argc; i++) {
        lua_pushstring(L, argv[i]);
        lua_pushboolean(L, 1);
        lua_settable(L, -3);
    }
    lua_setglobal(L, "arg");
    lua_getglobal(L, "package");
    lua_getfield(L, -1, "path");

    char* path = lua_tostring(L, -1);
    char* new_path = malloc(sizeof(char) * (strlen(path) + strlen(";" LUA_SCRIPTS) + 1));
    memcpy(new_path, path, strlen(path));
    memcpy(new_path + strlen(path), ";" LUA_SCRIPTS, strlen(";" LUA_SCRIPTS) + 1);
    // printf("%s\n", new_path);
    lua_pop(L, 1);
    lua_pushstring(L, "path");
    lua_pushstring(L, new_path);
    lua_settable(L, -3);
    free(new_path);
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
    lua_pcall(L, 1, 1, 0);
    size_t len = lua_rawlen(L, -1);
    char* str = malloc(sizeof(char) * (len + 1));
    for (size_t i = 0; i < len; i++) {
        lua_rawgeti(L, -1, i + 1);
        char c = lua_tointeger(L, -1);
        str[i] = c;
        lua_pop(L, 1);
    }
    str[len] = '\0';
    printf("%s", str);
    free(str);
    return 1;
}
int aux_print_wstring(lua_State* L, const wchar_t* ws, size_t size) {
    lua_getglobal(L, "Global");
    lua_getfield(L, -1, "wchar_to_utf8");
    lua_newtable(L);
    int count = size / sizeof(wchar_t);
    for (size_t i = 0; i < count; i++) {
        lua_pushinteger(L, i + 1);
        lua_pushinteger(L, ws[i]);
        lua_settable(L, -3);
    }
    lua_pcall(L, 1, 1, 0);
    size_t len = lua_rawlen(L, -1);
    char* str = malloc(sizeof(char) * len);
    for (size_t i = 0; i < len; i++) {
        lua_rawgeti(L, -1, i + 1);
        char c = lua_tointeger(L, -1);
        str[i] = c;
        lua_pop(L, 1);
    }
    printf("%s", str);
    free(str);
    return 1;
}