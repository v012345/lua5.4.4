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
        const std::string &GET_PATH() const { return file_path; }
        static int REGISTER_TO_LUA(lua_State *L);
        static int CREATE_OBJECT(lua_State *L);
        static int DESTROY_OBJECT(lua_State *L);
        static int GET_PATH(lua_State *L);
        static XML *GET_XML(lua_State *L, int arg);
        static const luaL_Reg METHODS_MAP[];
        ~XML();
    };

    void REGISTER_LIBS_TO_LUA(lua_State *L);
    static const luaL_Reg LIBS[];

}