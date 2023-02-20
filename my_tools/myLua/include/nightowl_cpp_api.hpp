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
    int REGISTER_XML_TO_LUA(lua_State *L);
    void REGISTER_CPP_CLASSES_TO_LUA(lua_State *L);

    class XML
    {
    private:
        std::string file_path;

    public:
        XML(std::string file_path);
        const std::string &GetPath() const { return file_path; }
        ~XML();
    };
    int C_API_NEW_XML(lua_State *L);
    int C_API_RELEASE_XML(lua_State *L);
    int GetPath(lua_State *L);

    XML *GetXML(lua_State *L, int arg);
    static const luaL_Reg method[] = {
        {"GetPath", GetPath},
        {"new", C_API_NEW_XML},
        {"__gc", C_API_RELEASE_XML},
        {NULL, NULL}};
    static const luaL_Reg my_libs[] = {
        {"XML", REGISTER_XML_TO_LUA},
        {NULL, NULL}};

}