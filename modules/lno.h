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

#ifdef __cplusplus
}
#endif