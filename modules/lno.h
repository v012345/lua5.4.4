#pragma once

#ifdef _WIN32
#define LNO_EXPORT __declspec(dllexport)
#else
#define LNO_EXPORT
#endif

#ifdef __cplusplus
extern "C" {
#endif
LNO_EXPORT int luaopen_lno(lua_State* L);
LNO_EXPORT int lua_no_print_stack(lua_State* L);
LNO_EXPORT int lua_no_print_code(lua_State* L);

#ifdef __cplusplus
}
#endif