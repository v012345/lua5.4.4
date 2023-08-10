/*
** $Id: lcorolib.c $
** Coroutine Library
** See Copyright Notice in lua.h
*/

#define lcorolib_c
#define LUA_LIB

#include "lprefix.h"

#include <stdlib.h>

#include "lua.h"

#include "lauxlib.h"
#include "lualib.h"

static lua_State* getco(lua_State* L) {
    lua_State* co = lua_tothread(L, 1);
    luaL_argexpected(L, co, 1, "thread");
    return co;
}

/*
** Resumes a coroutine. Returns the number of results for non-error
** cases or -1 for errors.
*/
static int auxresume(lua_State* L, lua_State* co, int narg) {
    int status, nres;
    if (l_unlikely(!lua_checkstack(co, narg))) {
        lua_pushliteral(L, "too many arguments to resume");
        return -1; /* error flag */
    }
    // 从当前进程 L 拿走 narg 元素, 放到 co 的栈上
    lua_xmove(L, co, narg);
    // 这里 resume 进去之后, 只有主动 yield 或执行完毕才会从这里出来
    status = lua_resume(co, L, narg, &nres);
    if (l_likely(status == LUA_OK || status == LUA_YIELD)) {
        // 这里要检查一下, 看看栈够不够存返回值
        if (l_unlikely(!lua_checkstack(L, nres + 1))) {
            lua_pop(co, nres); /* remove results anyway */
            lua_pushliteral(L, "too many results to resume");
            return -1; /* error flag */
        }
        // 又把 yield 来的值放到 L 上
        lua_xmove(co, L, nres); /* move yielded values */
        return nres;
    } else {
        lua_xmove(co, L, 1); /* move error message */
        return -1; /* error flag */
    }
}

static int luaB_coresume(lua_State* L) {
    lua_State* co = getco(L);
    int r;
    r = auxresume(L, co, lua_gettop(L) - 1);
    if (l_unlikely(r < 0)) {
        lua_pushboolean(L, 0);
        lua_insert(L, -2);
        return 2; /* return false + error message */
    } else {
        lua_pushboolean(L, 1);
        // 把 true 放到第一个返回值
        lua_insert(L, -(r + 1));
        return r + 1; /* return true + 'resume' returns */
    }
}

static int luaB_auxwrap(lua_State* L) {
    // 拿到之前放到上值里的新进程
    lua_State* co = lua_tothread(L, lua_upvalueindex(1));
    // 这里 lua_gettop(L) 返回的就是 lua 闭包调用时的参数个数
    int r = auxresume(L, co, lua_gettop(L));
    // 如果 r < 0 , 那么就是出错了, 会返回会返回错误信息的
    if (l_unlikely(r < 0)) { /* error? */
        int stat = lua_status(co);
        if (stat != LUA_OK && stat != LUA_YIELD) { /* error in the coroutine? */
            stat = lua_closethread(co, L); /* close its tbc variables */
            lua_assert(stat != LUA_OK);
            lua_xmove(co, L, 1); /* move error message to the caller */
        }
        if (stat != LUA_ERRMEM && /* not a memory error and ... */
            lua_type(L, -1) == LUA_TSTRING) { /* ... error object is a string? */
            luaL_where(L, 1); /* add extra info, if available */
            lua_insert(L, -2);
            lua_concat(L, 2);
        }
        return lua_error(L); /* propagate error */
    }
    return r; // yield 出来的值的个数
}

static int luaB_cocreate(lua_State* L) {
    lua_State* NL;
    // 第一个参数必须是一个函数
    luaL_checktype(L, 1, LUA_TFUNCTION);
    NL = lua_newthread(L); // NL 在 L 的栈顶
    // 把函数放到 NL 之上
    lua_pushvalue(L, 1); /* move function to top */
    // 把 L 的栈顶 1 个元素剪切走到 NL 上
    lua_xmove(L, NL, 1); /* move function from L to NL */
    // 现在 NL 已经有一份函数了
    return 1; // 这里返回的就是 NL
}

static int luaB_cowrap(lua_State* L) {
    luaB_cocreate(L);
    // 上面执行完成后, L 的栈顶是 NL, 栈底是函数
    lua_pushcclosure(L, luaB_auxwrap, 1); // C 闭包带一个上值, 把栈顶 1 个元素当作上值
    // 上面执行完后, L 的栈顶是 luaB_auxwrap 的 C 闭包, 闭馆带 1 个上值, 为 NL
    return 1;
}

static int luaB_yield(lua_State* L) { //
    return lua_yield(L, lua_gettop(L));
}

#define COS_RUN 0
#define COS_DEAD 1
#define COS_YIELD 2
#define COS_NORM 3

static const char* const statname[] = {
    "running",
    "dead",
    "suspended",
    "normal",
};

static int auxstatus(lua_State* L, lua_State* co) {
    if (L == co)
        return COS_RUN;
    else {
        switch (lua_status(co)) {
            case LUA_YIELD: return COS_YIELD;
            case LUA_OK: {
                lua_Debug ar;
                if (lua_getstack(co, 0, &ar)) /* does it have frames? */
                    return COS_NORM; /* it is running */
                else if (lua_gettop(co) == 0)
                    return COS_DEAD;
                else
                    return COS_YIELD; /* initial state */
            }
            default: /* some error occurred */ return COS_DEAD;
        }
    }
}

static int luaB_costatus(lua_State* L) {
    // 查看某个进程的状态 "running", "dead", "suspended", "normal"
    lua_State* co = getco(L);
    lua_pushstring(L, statname[auxstatus(L, co)]);
    return 1;
}

static int luaB_yieldable(lua_State* L) {
    lua_State* co = lua_isnone(L, 1) ? L : getco(L);
    lua_pushboolean(L, lua_isyieldable(co));
    return 1;
}

static int luaB_corunning(lua_State* L) {
    int ismain = lua_pushthread(L);
    lua_pushboolean(L, ismain);
    // 返回当前进程, 和当前进程是不是主进程
    return 2;
}

static int luaB_close(lua_State* L) {
    // 只能关闭 dead 与 yield 的进程
    lua_State* co = getco(L);
    int status = auxstatus(L, co);
    switch (status) {
        case COS_DEAD:
        case COS_YIELD: {
            status = lua_closethread(co, L);
            if (status == LUA_OK) {
                lua_pushboolean(L, 1);
                return 1;
            } else {
                lua_pushboolean(L, 0);
                lua_xmove(co, L, 1); /* move error message */
                return 2;
            }
        }
        default: /* normal or running coroutine */ //
            return luaL_error(L, "cannot close a %s coroutine", statname[status]);
    }
}

static const luaL_Reg co_funcs[] = {
    {"create", luaB_cocreate},
    {"resume", luaB_coresume},
    {"running", luaB_corunning},
    {"status", luaB_costatus},
    {"wrap", luaB_cowrap},
    {"yield", luaB_yield},
    {"isyieldable", luaB_yieldable},
    {"close", luaB_close}, //
    {NULL, NULL},
};

LUAMOD_API int luaopen_coroutine(lua_State* L) {
    luaL_newlib(L, co_funcs);
    return 1;
}
