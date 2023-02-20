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
namespace NIGHTOWL_XML
{
    void C_API(lua_State *L);
    class nightowl_c_xml
    {
    private:
        /* data */
    public:
        nightowl_c_xml(/* args */);
        ~nightowl_c_xml();
    };
}