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
    system("chcp 65001");
#endif
    lua_State* L = luaL_newstate();
    luaL_openlibs(L);
    luaopen_lfs(L);
    luaopen_aux(L, argc, argv);

#ifdef LUA_SCRIPTS
    luaL_dofile(L, LUA_SCRIPTS);
#endif
    wchar_t ws[] = L"\x6211\x7231\x4F60\x1234\x9875\xD83D\xDE0B";
    wchar_t wc = L"\x808F";
    // 11100110 10011000 10100101
    // 110 011000 100101
    // 110 011000 100101
    // 11100110
    // printf("%s\n", ws); // 3
    aux_print_wchar(L, wc);
    aux_print_wstring(L, ws, sizeof(ws));
    return 0;
}
