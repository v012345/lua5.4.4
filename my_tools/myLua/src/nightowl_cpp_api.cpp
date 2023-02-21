
#include "nightowl_cpp_api.hpp"

namespace NIGHTOWL
{
    void REGISTER_LIBS_TO_LUA(lua_State *L)
    {
        const luaL_Reg *lib = libs;
        for (; lib->func; lib++)
        {
            luaL_requiref(L, lib->name, lib->func, 1);
            lua_pop(L, 1);
        }
    }

    XML::XML(std::string file_path)
    {
        this->file_path = file_path;
    }

    XML::~XML()
    {
    }

    const luaL_Reg XML::METHODS_MAP[] = {
        {"GetPath", XML::GetPath},
        {"new", XML::C_API_NEW_XML},
        {"__gc", XML::C_API_RELEASE_XML},
        {NULL, NULL}};

    int XML::C_API_NEW_XML(lua_State *L)
    {

        std::string path = luaL_checkstring(L, -1);
        // 创建userdata，搞到对象指针
        XML **ppStu = (XML **)lua_newuserdata(L, sizeof(XML));
        (*ppStu) = new XML(path);
        // 获取元表
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

    XML *XML::GetXML(lua_State *L, int arg)
    {
        // 从栈顶取userdata，这个是C++的对象指针
        luaL_checktype(L, arg, LUA_TUSERDATA);
        void *userData = luaL_checkudata(L, arg, "XML");
        luaL_argcheck(L, userData != NULL, 1, "user data error");
        return *(XML **)userData;
    }
    int XML::C_API_RELEASE_XML(lua_State *L)
    {
        XML *pStu = XML::GetXML(L, 1);
        if (pStu)
            delete pStu;
        return 1;
    }

    int XML::GetPath(lua_State *L)
    {
        XML *pStu = XML::GetXML(L, 1);

        const std::string &name = pStu->GetPath();
        lua_pushstring(L, name.c_str());
        return 1;
    }

}
