#include <lua.hpp>
#include <iostream>
#include <filesystem>
#include "md5file.h"

static int GetFileLastModifiedTimestamp(lua_State *L);
static int GetFilesInfoInDirectory(lua_State *L);
static int CopyFile(lua_State *L);
static int GetMainLuaFilePath(lua_State *L);
static int GetFileMd5(lua_State *L);
static int IsFileExist(lua_State *L);
static int GetCommandLineArgv(lua_State *L);

std::string sMainLuaFilePath;

int main(int argc, char const *argv[])
{
    if (argc > 1 && std::filesystem::exists(argv[1]))
    {

        std::cout << "enter " << argv[1] << std::endl;
        sMainLuaFilePath = argv[1];
        lua_State *L = luaL_newstate();
        luaL_openlibs(L);
        lua_newtable(L);
        for (size_t i = 0; i < argc; i++)
        {
            lua_pushinteger(L, i + 1);
            lua_pushstring(L, argv[i]);
            lua_settable(L, -3);
        }
        lua_setglobal(L, "argv");

        lua_register(L, "GetFileLastModifiedTimestamp", GetFileLastModifiedTimestamp);
        lua_register(L, "GetFilesInfoInDirectory", GetFilesInfoInDirectory);
        lua_register(L, "CopyFile", CopyFile);
        lua_register(L, "GetMainLuaFilePath", GetMainLuaFilePath);
        lua_register(L, "GetFileMd5", GetFileMd5);
        lua_register(L, "IsFileExist", IsFileExist);
        lua_register(L, "GetCommandLineArgv", GetCommandLineArgv);
        luaL_dofile(L, argv[1]);
        std::cout << "leave " << argv[1] << std::endl;
    }
    return 0;
}

static int GetFileLastModifiedTimestamp(lua_State *L)
{
    const char *file = lua_tostring(L, 1);
    size_t timestamp = std::filesystem::last_write_time(file).time_since_epoch() / std::chrono::milliseconds(1);
    lua_pushinteger(L, timestamp);
    return 1;
}

static int GetFilesInfoInDirectory(lua_State *L)
{
    lua_newtable(L);
    size_t i = 1;
    for (auto &&directoryOrFile : std::filesystem::directory_iterator(std::filesystem::path(lua_tostring(L, 1))))
    {
        lua_pushinteger(L, i);
        lua_newtable(L);
        {
            {
                lua_pushstring(L, "is_directory");
                lua_pushboolean(L, directoryOrFile.is_directory());
                lua_settable(L, -3);
            }
            {
                lua_pushstring(L, "last_write_time");
                lua_pushinteger(L, std::filesystem::last_write_time(directoryOrFile.path()).time_since_epoch() / std::chrono::milliseconds(1));
                lua_settable(L, -3);
            }
            {
                lua_pushstring(L, "filename");
                lua_pushstring(L, directoryOrFile.path().filename().string().c_str());
                lua_settable(L, -3);
            }
            {

                lua_pushstring(L, "md5");
                if (directoryOrFile.is_directory())
                    lua_pushstring(L, "");
                else
                    lua_pushstring(L, getFileMD5(directoryOrFile.path().string()).c_str());
                lua_settable(L, -3);
            }
        }
        lua_settable(L, -3);
        i++;
    }
    return 1;
}

static int CopyFile(lua_State *L)
{
    const char *from = lua_tostring(L, 1);
    const char *to = lua_tostring(L, 2);
    auto parent_path = std::filesystem::path(to).parent_path();
    if (!std::filesystem::exists(parent_path))
    {
        std::filesystem::create_directories(parent_path);
    }
    std::filesystem::copy(from, to, std::filesystem::copy_options::overwrite_existing);
    lua_pushboolean(L, true);
    return 1;
}

static int GetMainLuaFilePath(lua_State *L)
{
    lua_pushstring(L, std::filesystem::path(sMainLuaFilePath).parent_path().string().c_str());
    return 1;
}

static int GetFileMd5(lua_State *L)
{
    const char *file = lua_tostring(L, 1);
    lua_pushstring(L, getFileMD5(file).c_str());
    return 1;
}

static int IsFileExist(lua_State *L)
{
    const char *file = lua_tostring(L, 1);
    lua_pushboolean(L, std::filesystem::exists(file));
    return 1;
}

static int GetCommandLineArgv(lua_State *L)
{
    const char *file = lua_tostring(L, 1);
    lua_pushboolean(L, std::filesystem::exists(file));
    return 1;
}