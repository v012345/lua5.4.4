
#include "nightowl_cpp_api.hpp"

namespace NIGHTOWL
{
    XML::XML(std::string file_path)
    {
        this->file_path = file_path;
        this->result = this->doc.load_file(file_path.c_str());
    }
    int XML::GET_PARSER_RESULT(lua_State *L)
    {
        XML *xml = XML::GET(L, 1);

        const std::string &r = xml->getParseResult();
        lua_pushstring(L, r.c_str());
        return 1;
    }
    int XML::GET_PATH(lua_State *L)
    {
        XML *xml = XML::GET(L, 1);

        const std::string &p = xml->getPath();
        lua_pushstring(L, p.c_str());
        return 1;
    }
    XML::~XML()
    {
    }

    const luaL_Reg XML::METHODS_MAP[] = {
        {"getPath", XML::GET_PATH},
        {"new", XML::CREATE},
        {"__gc", XML::DESTROY},
        {NULL, NULL}};

    void REGISTER_LIBS_TO_LUA(lua_State *L)
    {
        const luaL_Reg *lib = LIBS;
        for (; lib->func; lib++)
        {
            luaL_requiref(L, lib->name, lib->func, 1);
            lua_pop(L, 1);
        }
    }

    int XML::CREATE(lua_State *L)
    {

        std::string path = luaL_checkstring(L, -1);
        XML **xml = (XML **)lua_newuserdata(L, sizeof(XML *));
        *xml = new XML(path);
        luaL_getmetatable(L, "XML");
        lua_setmetatable(L, -2);
        return 1;
    }

    int XML::REGISTER_TO_LUA(lua_State *L)
    {
        luaL_newmetatable(L, "XML");
        lua_pushvalue(L, -1);
        lua_setfield(L, -2, "__index");
        luaL_setfuncs(L, METHODS_MAP, 0);
        return 1;
    }

    XML *XML::GET(lua_State *L, int arg)
    {
        luaL_checktype(L, arg, LUA_TUSERDATA);
        void *userData = luaL_checkudata(L, arg, "XML");
        luaL_argcheck(L, userData != NULL, 1, "user data error");
        return *(XML **)userData;
    }
    int XML::DESTROY(lua_State *L)
    {
        XML *xml = XML::GET(L, 1);
        if (xml)
            delete xml;
        return 1;
    }

}
