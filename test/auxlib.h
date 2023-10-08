#pragma once
#ifdef LUA_AUX_LIB
#include "lauxlib.h"
#include "lua.h"
#include "lualib.h"
int luaopen_aux(lua_State* L, int argc, char const* argv[]);
int aux_print_wchar(lua_State*, wchar_t);
int aux_print_wstring(lua_State* L, const wchar_t* ws, size_t size);

#endif