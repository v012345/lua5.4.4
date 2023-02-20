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
    int SET_METATABLE(lua_State *L);
    void LUA_REGISTER_CPP_CLASS(lua_State *L);

    class XML
    {
    private:
        std::string file_path;

    public:
        XML(std::string file_path);
        const std::string& GetPath() const { return file_path; }
        ~XML();
    };
    int C_API_NEW_XML(lua_State *L);
    int C_API_RELEASE_XML(lua_State *L);
    int GetPath(lua_State *L);

    XML *GetXML(lua_State *L, int arg);
    static const luaL_Reg method[] = {
        // {"SetAge", pcf_SetAge},
        // {"GetAge", pcf_GetAge},
        // {"SetName", pcf_SetName},
        {"GetPath", GetPath},
        // {"ShowSelfInfo", pcf_ShowSelfInfo},
        {"new", C_API_NEW_XML},
        {"__gc", C_API_RELEASE_XML},
        {NULL, NULL}};
    static const luaL_Reg libs[] = {
        {"XML", SET_METATABLE},
        {NULL, NULL}};

}