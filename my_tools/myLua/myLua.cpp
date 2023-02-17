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

static int GetFileLastModifiedTimestamp(lua_State *L);
static int GetFilesInfoInDirectory(lua_State *L);
static int CopyFile(lua_State *L);
static int GetMainLuaFilePath(lua_State *L);
static int GetFileMd5(lua_State *L);
static int IsFileExist(lua_State *L);
static int GetFilesTypeInDirectory(lua_State *L);
static int CopyFileMultiThreads(lua_State *L);
int StackDump(lua_State *L);
int GetFilesMd5(lua_State *L);
int Test(lua_State *L);

std::string sMainLuaFilePath;

int main(int argc, char const *argv[])
{
    for (size_t i = 0; i < argc; i++)
    {
        std::cout << argv[i] << std::endl;
    }

    if (argc > 1 && std::filesystem::exists(argv[1]))
    {
        std::cout << "enter " << argv[1] << std::endl;
        sMainLuaFilePath = argv[1];
        lua_State *L = luaL_newstate();
        luaL_openlibs(L);
        lua_newtable(L);
        for (size_t i = 2; i < argc; i++)
        {

            if (std::string("-m").compare(argv[i]) == 0)
            {
                lua_pushstring(L, "module");
                lua_pushstring(L, argv[i + 1]);
                lua_settable(L, -3);
            }
            if (std::string("-b").compare(argv[i]) == 0)
            {
                lua_pushstring(L, "branch");
                lua_pushstring(L, argv[i + 1]);
                lua_settable(L, -3);
            }
        }
        lua_setglobal(L, "argv");

        lua_register(L, "GetFileLastModifiedTimestamp", GetFileLastModifiedTimestamp);
        lua_register(L, "GetFilesInfoInDirectory", GetFilesInfoInDirectory);
        lua_register(L, "CopyFile", CopyFile);
        lua_register(L, "GetMainLuaFilePath", GetMainLuaFilePath);
        lua_register(L, "GetFileMd5", GetFileMd5);
        lua_register(L, "IsFileExist", IsFileExist);
        lua_register(L, "GetFilesTypeInDirectory", GetFilesTypeInDirectory);
        lua_register(L, "CopyFileMultiThreads", CopyFileMultiThreads);
        lua_register(L, "StackDump", StackDump);
        lua_register(L, "GetFilesMd5", GetFilesMd5);
        lua_register(L, "Test", Test);
        if (std::filesystem::exists(argv[1]))
        {
            luaL_dofile(L, argv[1]);
            std::cout << "leave " << argv[1] << std::endl;
        }
        else
        {
            std::cout << "miss file " << argv[1] << std::endl;
        }
        std::cout << "bye bye" << std::endl;
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

static int GetFilesTypeInDirectory(lua_State *L)
{
    lua_newtable(L);
    lua_newtable(L);
    for (auto &&directoryOrFile : std::filesystem::directory_iterator(std::filesystem::path(lua_tostring(L, 1))))
    {
        lua_pushstring(L, directoryOrFile.path().filename().string().c_str());
        lua_pushboolean(L, directoryOrFile.is_directory());
        lua_settable(L, -3);
    }
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

int GetFilesMd5(lua_State *L)
{
    luaL_checktype(L, 1, LUA_TTABLE);
    std::vector<std::string> files;

    size_t n = lua_rawlen(L, 1);

    for (size_t i = 1; i <= n; i++)
    {
        int ret_type = lua_rawgeti(L, 1, i);
        if (ret_type == LUA_TSTRING)
        {
            files.push_back(lua_tostring(L, -1));
        }
        lua_pop(L, 1);
    }
    int processor_count = std::thread::hardware_concurrency();
    std::vector<std::thread> workers;
    std::map<std::string, std::string> filesMd5;
    std::mutex mutex;
    std::mutex mutex2;
    for (size_t i = 0; i < processor_count; i++)
    {
        workers.push_back(std::thread([&]()
                                      {
            while (true)
        {
            mutex.lock();
            if (files.empty())
            {
                mutex.unlock();
                return;
            }
            std::string file = files.front();
            files.erase(files.begin());
            mutex.unlock();
            std::string md5 = getFileMD5(file);
            mutex2.lock();
            filesMd5.insert(std::make_pair(file, md5));
            mutex2.unlock();
        } }));
    }
    for (auto &&worker : workers)
    {
        worker.join();
    }

    lua_newtable(L);
    for (auto &&file : filesMd5)
    {
        lua_pushstring(L, file.first.c_str());
        lua_pushstring(L, file.second.c_str());
        lua_settable(L, -3);
    }
    return 1;
}

static int CopyFileMultiThreads(lua_State *L)
{
    std::cout << "CopyFileMultiThreads" << std::endl;
    luaL_checktype(L, 1, LUA_TTABLE);
    lua_pushnil(L);
    std::map<std::string, std::string> copyFilesList;
    std::vector<std::thread> copyWorkers;
    std::mutex mutex;
    while (lua_next(L, -2))
    {
        std::string from = lua_tostring(L, -2);
        // const char *from =
        std::string to = lua_tostring(L, -1);
        // const char *to = lua_tostring(L, -1);
        // printf("%s => %s\n", key, val);
        if (false)
        {
            auto parent_path = std::filesystem::path(to).parent_path();
            if (!std::filesystem::exists(parent_path))
            {
                std::filesystem::create_directories(parent_path);
            }

            std::filesystem::copy(from, to, std::filesystem::copy_options::overwrite_existing);
        }
        else
        {
            copyFilesList.insert(std::make_pair(from, to));
        }

        lua_pop(L, 1); // 把栈顶的值移出栈，让key成为栈顶以便继续遍历
    }
    for (size_t i = 0; i < 6; i++)
    {
        copyWorkers.push_back(std::thread([&]()
                                          {
            while (true)
        {
            mutex.lock();
            if (copyFilesList.empty())
            {
                mutex.unlock();
                return;
            }
            std::string form_ = copyFilesList.begin()->first;
            std::string to_ = copyFilesList.begin()->second;
            copyFilesList.erase(copyFilesList.begin());
            // table_name = all_tables.front();
            // primary_key = primary_keys.front();
            // primary_keys.erase(primary_keys.begin());
            // all_tables.erase(all_tables.begin());
            mutex.unlock();
            auto parent_path = std::filesystem::path(to_).parent_path();
            if (!std::filesystem::exists(parent_path))
            {
                std::filesystem::create_directories(parent_path);
            }
            // std::filesystem::copy(form_, to_, std::filesystem::copy_options::overwrite_existing);
            getFileMD5(form_);
        } }));
    }
    int processor_count = std::thread::hardware_concurrency();
    for (auto &&copyWorker : copyWorkers)
    {
        copyWorker.join();
    }

    return 0;
}

int LuaArrayToCpp(lua_State *L)
{
    luaL_checktype(L, 1, LUA_TTABLE);
    int n = lua_rawlen(L, 1);
    for (int i = 1; i <= n; i++)
    {
        int ret_type = lua_rawgeti(L, 1, i);
        if (ret_type == LUA_TNUMBER)
        {
            if (lua_isinteger(L, -1))
            {
                printf("%lld\n", lua_tointeger(L, -1));
            }
            else if (lua_isnumber(L, -1))
            {
                printf("%g\n", lua_tonumber(L, -1));
            }
        }
        else if (ret_type == LUA_TSTRING)
        {
            printf("%s\n", lua_tostring(L, -1));
        }
        lua_pop(L, 1);
    }
    return 0;
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

int Test(lua_State *L)
{
    std::cout << lua_gettop(L) << std::endl;
    // std::cout << lua_gettop(L) << std::endl;
    // lua_pushstring(L, "aaa");
    // std::cout << lua_gettop(L) << std::endl;
    // lua_gettable(L, 5);
    // std::cout << lua_gettop(L) << std::endl;
    // lua_settop(L, 1);
    lua_pushstring(L, "cc");
    lua_rawget(L, -2);
    // lua_getfield(L, -1, "cc");
    lua_pushstring(L, "aa");
    lua_rawget(L, -2);
    // lua_getfield(L, -1, "aa");
    std::cout << lua_gettop(L) << std::endl;
    std::cout << lua_tostring(L, -1) << std::endl;
    // lua_getfield(L, 6, "cc");
    lua_pushstring(L, "cc");
    lua_rawget(L, 6);
    // std::cout << lua_gettop(L) << std::endl;
    lua_pushstring(L, "aa");
    lua_pushstring(L, ">>>>>>>>>>>>>>>");
    // lua_setfield(L, -2, "aa");
    lua_rawset(L, -3);
    lua_pushstring(L, "aa");
    lua_rawget(L, -2);
    // lua_getfield(L, -1, "aa");
    // lua_pushstring(L,">>>>>>>>>>>>>>>");
    // lua_getfield(L, -2, "aa");
    // lua_getfield(L, -1, "aa");
    std::cout << lua_type(L, lua_gettop(L)) << std::endl;
    std::cout << lua_tostring(L, -1) << std::endl;
    std::cout << lua_typename(L,lua_type(L,-1)) << std::endl;
    // std::cout << lua_tostring(L, -1) << std::endl;
    // std::cout << lua_gettop(L) << std::endl;
    return 0;
}

int StackDump(lua_State *L)
{
    std::cout << "\nbegin dump lua stack" << std::endl;
    int top = lua_gettop(L);
    for (int i = 1; i <= top; ++i)
    {
        int t = lua_type(L, i);
        switch (t)
        {
        case LUA_TSTRING:
        {
            printf("'%s' ", lua_tostring(L, i));
        }
        break;
        case LUA_TBOOLEAN:
        {
            printf(lua_toboolean(L, i) ? "true " : "false ");
        }
        break;
        case LUA_TNUMBER:
        {
            printf("%g ", lua_tonumber(L, i));
        }
        break;
        default:
        {
            printf("%s ", lua_typename(L, t));
        }
        break;
        }
    }
    std::cout << "\nend dump lua stack" << std::endl;
    return 0;
}
