#pragma once
#include <chrono>
#include <filesystem>
#include <iostream>
#include <lua.hpp>
#include <map>
#include <mutex>
#include <stdio.h>
#include <string>
#include <thread>
#include <unordered_set>
#include <vector>
#include "lobject.h"
#include "lstate.h"
namespace NIGHTOWL {
int GetFileLastModifiedTimestamp(lua_State* L);
int CopyFile(lua_State* L);
int GetFileMd5(lua_State* L);
int IsFileExist(lua_State* L);
int Lua_GetFilesInFolder(lua_State* L);
void GetFilesInFolder(lua_State* L, std::filesystem::path folder, std::unordered_set<std::string>& exclude);
int CopyFileMultiThreads(lua_State* L);
int StackDump(lua_State* L);
int GetFilesMd5(lua_State* L);
int DeleteFile(lua_State* L);
int Test(lua_State* L);
int GetFilesLastModifiedTimestamp(lua_State* L);
void C_API(lua_State* L);
int GetOpCodes(lua_State* L);
} // namespace NIGHTOWL