#include "lauxlib.h"
#include "lua.h"
#include "lualib.h"
#include <limits.h>
#include <locale.h>
#include <stdio.h>
#include <stdlib.h>
#include <wchar.h>
int main(int argc, char const* argv[]) {
    printf("12");
#ifdef _WIN32 // _WIN32 在 32 和 64 位上都有定义, _WIN64 只在 64 位上有定义
    system("chcp 65001");
#endif
    lua_State* L = luaL_newstate();
    luaL_openlibs(L);
    luaopen_lfs(L);

    lua_newtable(L);
    for (int i = 0; i < argc; i++) {
        lua_pushstring(L, argv[i]);
        lua_pushboolean(L, 1);
        lua_settable(L, -3);
    }
    lua_setglobal(L, "arg");
#ifdef LUA_SCRIPTS
    luaL_dofile(L, LUA_SCRIPTS);
#endif
    // setlocale(LC_ALL, "UTF-32");
    /* code */
    // freopen("output.txt", "w", stdout);
    // printf("hello");

    //     fprintf(stdout, "hello\n");
    //     fprintf(stdout, "%d\n", MB_LEN_MAX);
    //     fprintf(stdout, "%d\n", MB_CUR_MAX);
    //     char* s = "牛";
    //     unsigned char* p = s;
    //     for (size_t i = 0; i < 7; i++) { //
    //         printf("%2x\t", (*(p + i)));
    //     }
    //     printf("%2x\t", -1);
    //     printf("%zd\t", sizeof(*p));
    //     printf("\n");
    //     // 11100111 10001001 10011011;

    //     // 0111001001011011;
    //     // 0111001001011011;
    //     printf("%s\n", s); // 春天
    //     s = "\u0024\u4F60\u0061";
    //     printf("%s\n", s); // @$`

    //     wchar_t c = L'a';
    //     printf("%lc\n", c);

    //     wchar_t* ws = L"春天牛";
    //     printf("%ls\n", ws);
    //     char* mbs1 = "春天";
    //     printf("%d\n", mblen(mbs1, MB_CUR_MAX)); // 3

    //     char* mbs2 = "abc";
    //     printf("%d\n", mblen(mbs2, MB_CUR_MAX)); // 1
    return 0;
}
