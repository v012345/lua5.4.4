#include <lua.hpp>
extern "C" {
#include <lfs.h>
#include <lgc.h>
#include <lno.h>
#include <lobject.h>
#include <lstate.h>
}
#define LUA_MAIN_SCRIPT "./main.lua"
#define LUA_CODE_SCRIPT "./bytedump.lua"
static int C_CompileFile(lua_State* L);
int main(int argc, char const* argv[]) {
    lua_State* L = luaL_newstate();
    luaL_openlibs(L);
    luaopen_lfs(L);
    lua_register(L, "Compile", C_CompileFile);
    luaL_dofile(L, LUA_MAIN_SCRIPT);
    return 0;
}

static void praserProto(lua_State* L, Proto* p) {
    lua_newtable(L);

    lua_pushstring(L, "code");
    lua_newtable(L);
    for (size_t i = 0; i < p->sizecode; i++) {
        lua_pushinteger(L, i + 1);
        lua_pushinteger(L, p->code[i]);
        lua_settable(L, -3);
    }
    lua_settable(L, -3);

    lua_pushstring(L, "k");
    lua_newtable(L);
    for (size_t i = 0; i < p->sizek; i++) {
        lua_pushinteger(L, i + 1);
        TValue* o = &p->k[i];
        // #define LUA_TNIL 0
        // #define LUA_TBOOLEAN 1
        // #define LUA_TLIGHTUSERDATA 2
        // #define LUA_TNUMBER 3
        // #define LUA_TSTRING 4
        // #define LUA_TTABLE 5
        // #define LUA_TFUNCTION 6
        // #define LUA_TUSERDATA 7
        // #define LUA_TTHREAD 8
        printf("%d\t", ttype(o));
        if (ttype(o) == LUA_TSTRING) { /* code */
            lua_pushstring(L, getstr(tsvalue(o)));
        } else {
            lua_pushinteger(L, i + 1);
        }

        lua_settable(L, -3);
    }
    lua_settable(L, -3);

    lua_pushstring(L, "locvars");
    lua_newtable(L);
    for (size_t i = 0; i < p->sizelocvars; i++) {
        lua_pushinteger(L, i + 1);
        lua_pushstring(L, getstr(p->locvars[i].varname));
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

    lua_pushstring(L, "p");
    lua_newtable(L);
    for (size_t i = 0; i < p->sizep; i++) {
        lua_pushinteger(L, i + 1);
        praserProto(L, p->p[i]);
        lua_settable(L, -3);
    }
    lua_settable(L, -3);
}

static int C_CompileFile(lua_State* L) {
    const char* file = lua_tostring(L, 1);
    luaL_loadfile(L, file);
    TValue* tv = s2v(L->top.p - 1);
    LClosure* LC = clLvalue(tv);
    Proto* p = LC->p;
    praserProto(L, p);
    return 1;
}