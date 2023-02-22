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
#include "pugixml.hpp"
namespace NIGHTOWL
{

    class XML
    {
    private:
        std::string file_path;
        pugi::xml_document doc;
        pugi::xml_parse_result result;

    public:
        XML(std::string file_path);
        const std::string &getPath() const { return file_path; }
        const std::string &getParseResult() const { return result.description(); }

        static int CREATE(lua_State *L);
        static int DESTROY(lua_State *L);
        static int GET_PATH(lua_State *L);
        static int GET_PARSER_RESULT(lua_State *L);
        static const luaL_Reg METHODS_MAP[];

        static XML *GET(lua_State *L, int arg);

        static int REGISTER_TO_LUA(lua_State *L);

        ~XML();
    };

    void REGISTER_LIBS_TO_LUA(lua_State *L);
    static const luaL_Reg LIBS[] = {
        {"XML", XML::REGISTER_TO_LUA},
        {NULL, NULL}};

}