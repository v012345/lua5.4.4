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
namespace NIGHTOWL
{
    int GetFileLastModifiedTimestamp(lua_State *L);
    int CopyFile(lua_State *L);
    int GetFileMd5(lua_State *L);
    int IsFileExist(lua_State *L);
    int Lua_GetFilesInFolder(lua_State *L);
    void GetFilesInFolder(lua_State *L, std::filesystem::path folder, std::unordered_set<std::string> &exclude);
    int CopyFileMultiThreads(lua_State *L);
    int StackDump(lua_State *L);
    int GetFilesMd5(lua_State *L);
    int DeleteFile(lua_State *L);
    int Test(lua_State *L);
    int GetFilesLastModifiedTimestamp(lua_State *L);
    void C_API(lua_State *L);
}