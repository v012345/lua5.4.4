#pragma once
#include <lua.hpp>
#include <iostream>
#include <filesystem>
#include <map>
#include <thread>
#include <vector>
#include <mutex>
#include <chrono>
#include <string>
#include <unordered_set>
#include "md5file.h"
#include "pugiconfig.hpp"
namespace NIGHTOWL
{

    class XML
    {
    private:
        std::string file_path;

    public:
        XML(std::string file_path);
        const std::string &GetPath() const { return file_path; }
        static int REGISTER_TO_LUA(lua_State *L);
        static int C_API_NEW_XML(lua_State *L);
        static int C_API_RELEASE_XML(lua_State *L);
        static int GetPath(lua_State *L);
        static XML *GetXML(lua_State *L, int arg);
        static const luaL_Reg METHODS_MAP[];
        ~XML();
    };

    void REGISTER_LIBS_TO_LUA(lua_State *L);
    static const luaL_Reg libs[] = {
        {"XML", XML::REGISTER_TO_LUA},
        {NULL, NULL}};

}