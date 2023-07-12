#include <lua.hpp>
extern "C" {
#include <lfs.h>
#include <lno.h>
#include <lobject.h>
#include <lstate.h>
}

#include <fstream>
#include <iostream>
#include <winsock.h>
#define LUA_MAIN_SCRIPT "./main.lua"
#define LUA_CODE_SCRIPT "./bytedump.lua"

static int dump(lua_State* L);
static void lua_pushTValue(lua_State* L, TValue* v);
static int GetImageSize(lua_State* L);

int main(int argc, char const* argv[]) {
    lua_State* L = luaL_newstate();
    luaL_openlibs(L);
    luaopen_lfs(L);
    lua_register(L, "ChunkDump", &dump);
    luaL_dofile(L, LUA_MAIN_SCRIPT);
    return 0;
}
static int dump(lua_State* L) {
    const char* path = lua_tostring(L, 1);

    if (luaL_loadfile(L, path) == LUA_OK) {
        StkId f = L->top.p - 1;
        Proto* p = clLvalue(s2v(f))->p;
        lua_newtable(L);
        lua_pushstring(L, "source");
        lua_pushstring(L, getstr(p->source));
        lua_settable(L, -3);
        lua_pushstring(L, "numparams");
        lua_pushinteger(L, p->numparams);
        lua_settable(L, -3);
        lua_pushstring(L, "is_vararg");
        lua_pushboolean(L, p->is_vararg != 0);
        lua_settable(L, -3);
        lua_pushstring(L, "maxstacksize");
        lua_pushinteger(L, p->maxstacksize);
        lua_settable(L, -3);
        lua_pushstring(L, "sizeupvalues");
        lua_pushinteger(L, p->sizeupvalues);
        lua_settable(L, -3);
        lua_pushstring(L, "sizek");
        lua_pushinteger(L, p->sizek);
        lua_settable(L, -3);
        lua_pushstring(L, "sizecode");
        lua_pushinteger(L, p->sizecode);
        lua_settable(L, -3);
        lua_pushstring(L, "sizelineinfo");
        lua_pushinteger(L, p->sizelineinfo);
        lua_settable(L, -3);
        lua_pushstring(L, "sizep");
        lua_pushinteger(L, p->sizep);
        lua_settable(L, -3);
        lua_pushstring(L, "sizelocvars");
        lua_pushinteger(L, p->sizelocvars);
        lua_settable(L, -3);
        lua_pushstring(L, "sizeabslineinfo");
        lua_pushinteger(L, p->sizeabslineinfo);
        lua_settable(L, -3);
        lua_pushstring(L, "linedefined");
        lua_pushinteger(L, p->linedefined);
        lua_settable(L, -3);
        lua_pushstring(L, "lastlinedefined");
        lua_pushinteger(L, p->lastlinedefined);
        lua_settable(L, -3);
        lua_pushstring(L, "k");
        lua_newtable(L);
        for (size_t i = 0; i < p->sizek; i++) {
            TValue k = p->k[i];
            lua_pushinteger(L, i + 1);
            lua_pushTValue(L, &k);
            lua_settable(L, -3);
        }
        lua_settable(L, -3);

    } else {
        lua_newtable(L);
    }

    return 1;
}

static void lua_pushTValue(lua_State* L, TValue* v) {

    if (ttype(v) == LUA_TSTRING) {
        lua_pushstring(L, getstr(cast(TString*, val_(v).gc)));
    } else if (ttype(v) == LUA_TNUMBER) {
        if (ttypetag(v) == LUA_VNUMFLT) {
            lua_pushnumber(L, val_(v).n);
        } else {
            lua_pushinteger(L, val_(v).i);
        }

    } else {
        lua_pushstring(L, lua_typename(L, ttype(v)));
    }
}

static int GetImageSize(lua_State* L) {
    std::ifstream in(lua_tostring(L, 1));
    unsigned int width, height;

    in.seekg(16);
    in.read((char*)&width, 4);
    in.read((char*)&height, 4);

    width = ntohl(width);
    height = ntohl(height);
    return 1;
}