#include <lauxlib.h>
#include <lobject.h>
#include <lstate.h>
#include <lua.h>
#include <lualib.h>

#include "lno.h"
LNO_EXPORT int luaopen_lno(lua_State* L) { return 1; }
LNO_EXPORT int lua_no_print_code(lua_State* L) { return 1; }
LNO_EXPORT int lua_no_print_stack(lua_State* L) {
    StkId current_stack = L->stack.p;
    int i = 1;
    while (current_stack != L->top.p) {
        printf("%d\t", i++);
        TValue* tv = s2v(current_stack);
        printf("%d\t", ttype(tv));
        printf("\n");
        current_stack++;
    }

    // CallInfo* ci = L->ci; // 指的当前的 c 函数调用
    // ci = ci->previous;
    // TValue* tv = s2v(ci->func.p);
    // LClosure* LC = clLvalue(tv);
    // Proto* p = LC->p;
    // for (size_t i = 0; i < p->sizecode; i++) { //
    //     printf("%s\n", p->code[i]);
    // }
    // printf(getstr(p->source));
    return 1;
}
