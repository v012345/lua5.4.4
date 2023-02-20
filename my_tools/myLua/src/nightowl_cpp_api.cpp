
#include "nightowl_cpp_api.hpp"

namespace NIGHTOWL
{
    void REGISTER_CPP_CLASSES_TO_LUA(lua_State *L)
    {
        const luaL_Reg *lib = my_libs;
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

    int C_API_NEW_XML(lua_State *L)
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

    int REGISTER_XML_TO_LUA(lua_State *L)
    {
        std::cout << lua_gettop(L) << std::endl;
        luaL_newmetatable(L, "XML");
        std::cout << lua_gettop(L) << std::endl;
        lua_pushvalue(L, -1);
         std::cout << lua_gettop(L) << std::endl;
        lua_setfield(L, -2, "__index");
        luaL_setfuncs(L, method, 0);
        return 1;
    }

    XML *GetXML(lua_State *L, int arg)
    {
        // 从栈顶取userdata，这个是C++的对象指针
        luaL_checktype(L, arg, LUA_TUSERDATA);
        void *userData = luaL_checkudata(L, arg, "XML");
        luaL_argcheck(L, userData != NULL, 1, "user data error");
        return *(XML **)userData;
    }
    int C_API_RELEASE_XML(lua_State *L)
    {
        XML *pStu = GetXML(L, 1);
        if (pStu)
            delete pStu;
        return 1;
    }

    int GetPath(lua_State *L)
    {
        XML *pStu = GetXML(L, 1);

        const std::string &name = pStu->GetPath();
        lua_pushstring(L, name.c_str());
        return 1;
    }

}
