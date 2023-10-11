#include "auxlib.h"
#include "lauxlib.h"
#include "lfs.h"
#include "lua.h"
#include "lualib.h"
#include <limits.h>
#include <locale.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <wchar.h>

int main(int argc, char const* argv[]) {
#ifdef _WIN32 // _WIN32 在 32 和 64 位上都有定义, _WIN64 只在 64 位上有定义
    system("chcp 65001 > NUL");
    system("chcp 65001 > $null");
#endif
    lua_State* L = luaL_newstate();
    luaL_openlibs(L);
    luaopen_lfs(L);
    luaopen_aux(L, argc, argv);

#ifdef LUA_MAIN_ENTRY
    luaL_dofile(L, LUA_MAIN_ENTRY);
#endif
    wchar_t wc = L'\x518D';
    wchar_t ws[] = L"\x89C1\xD83D\xDC4B";
    aux_print_wchar(L, wc);
    aux_print_wstring(L, ws, sizeof(ws));
    return 0;
}
