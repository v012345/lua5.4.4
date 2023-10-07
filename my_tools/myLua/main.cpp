#include <lua.hpp>
extern "C" {
#include <lapi.h>
#include <lfs.h>
#include <lgc.h>
#include <lno.h>
#include <lobject.h>
#include <lstate.h>
}
#define LUA_MAIN_SCRIPT "./main.lua"
#define LUA_CODE_SCRIPT "./bytedump.lua"
static int luac(lua_State* L);
static void praser(lua_State* L, Proto* p);
int main(int argc, char const* argv[]) {
    return 0;
    lua_State* L = luaL_newstate();
    luaL_openlibs(L);
    luaopen_lfs(L);
    lua_register(L, "luac", luac);
    lua_newtable(L);
    for (int i = 0; i < argc; i++) {
        lua_pushstring(L, argv[i]);
        lua_pushboolean(L, 1);
        lua_settable(L, -3);
    }
    lua_setglobal(L, "arg");

    luaL_dofile(L, LUA_MAIN_SCRIPT);
    return 0;
}

static int luac(lua_State* L) {
    const char* file = lua_tostring(L, 1);
    luaL_loadfile(L, file);
    TValue* tv = s2v(L->top.p - 1);
    LClosure* LC = clLvalue(tv);
    Proto* p = LC->p;
    praser(L, p);
    return 1;
}

static void praser(lua_State* L, Proto* p) {
    lua_newtable(L);

    lua_pushstring(L, "locvars");
    lua_newtable(L);
    for (size_t i = 0; i < p->sizelocvars; i++) {
        lua_pushinteger(L, i + 1);
        lua_pushstring(L, getstr(p->locvars[i].varname));
        lua_settable(L, -3);
    }
    lua_settable(L, -3);

    lua_pushstring(L, "k");
    lua_newtable(L);
    for (size_t i = 0; i < p->sizek; i++) {
        lua_pushinteger(L, i + 1);
        TValue* o = &p->k[i];
        if (rawtt(o) == LUA_VNIL) { /* code */
            lua_pushstring(L, "nil");
        } else {
            setobj(L, cast(TValue*, L->top.p), o);
            api_incr_top(L);
        }
        lua_settable(L, -3);
    }
    lua_settable(L, -3);

    lua_pushstring(L, "upvalues");
    lua_newtable(L);
    for (size_t i = 0; i < p->sizeupvalues; i++) {
        lua_pushinteger(L, i + 1);
        lua_newtable(L);

        lua_pushstring(L, "name");
        lua_pushstring(L, getstr(p->upvalues[i].name));
        lua_settable(L, -3);

        lua_pushstring(L, "instack");
        lua_pushboolean(L, p->upvalues[i].instack);
        lua_settable(L, -3);

        lua_pushstring(L, "idx");
        lua_pushinteger(L, p->upvalues[i].idx);
        lua_settable(L, -3);

        lua_pushstring(L, "kind");
        lua_pushinteger(L, p->upvalues[i].kind);
        lua_settable(L, -3);

        lua_settable(L, -3);
    }
    lua_settable(L, -3);

    lua_pushstring(L, "code");
    lua_newtable(L);
    for (size_t i = 0; i < p->sizecode; i++) {
        lua_pushinteger(L, i + 1);
        lua_pushinteger(L, p->code[i]);
        lua_settable(L, -3);
    }
    lua_settable(L, -3);

    lua_pushstring(L, "p");
    lua_newtable(L);
    for (size_t i = 0; i < p->sizep; i++) {
        lua_pushinteger(L, i + 1);
        praser(L, p->p[i]);
        lua_settable(L, -3);
    }
    lua_settable(L, -3);

    lua_pushstring(L, "abslineinfo");
    lua_newtable(L);
    for (size_t i = 0; i < p->sizeabslineinfo; i++) {
        lua_pushinteger(L, p->abslineinfo[i].pc);
        lua_pushinteger(L, p->abslineinfo[i].line);
        lua_settable(L, -3);
    }
    lua_settable(L, -3);
}