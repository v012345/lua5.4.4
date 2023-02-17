#include <lua.hpp>
#include <iostream>
#include <filesystem>
#include <map>
#include <thread>
#include <vector>
#include <mutex>
#include <chrono>
#include <string>
#include "md5file.h"
namespace NIGHTOWL
{
    int GetFileLastModifiedTimestamp(lua_State *L);
    int GetFilesInfoInDirectory(lua_State *L);
    int CopyFile(lua_State *L);
    int GetFileMd5(lua_State *L);
    int IsFileExist(lua_State *L);
    int GetFilesTypeInDirectory(lua_State *L);
    int CopyFileMultiThreads(lua_State *L);
    int StackDump(lua_State *L);
    int GetFilesMd5(lua_State *L);
    int Test(lua_State *L);
    void C_API(lua_State *L);
}