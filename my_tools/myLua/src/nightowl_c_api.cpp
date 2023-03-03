
#include "nightowl_c_api.h"

namespace NIGHTOWL
{
    void C_API(lua_State *L)
    {
        lua_register(L, "GetFileLastModifiedTimestamp", GetFileLastModifiedTimestamp);
        lua_register(L, "CopyFile", CopyFile);
        lua_register(L, "DeleteFile", DeleteFile);
        lua_register(L, "GetFileMd5", GetFileMd5);
        lua_register(L, "IsFileExist", IsFileExist);
        lua_register(L, "GetFilesInFolder", Lua_GetFilesInFolder);
        lua_register(L, "CopyFileMultiThreads", CopyFileMultiThreads);
        lua_register(L, "StackDump", StackDump);
        lua_register(L, "GetFilesLastModifiedTimestamp", GetFilesLastModifiedTimestamp);
        lua_register(L, "GetFilesMd5", GetFilesMd5);
        lua_register(L, "Test", Test);
    }

    int GetFilesLastModifiedTimestamp(lua_State *L)
    {
        std::vector<std::string> timestamp;

        size_t filesCount = lua_rawlen(L, 1);

        for (size_t i = 1; i <= filesCount; i++)
        {
            lua_rawgeti(L, 1, i);
            std::string file = lua_tostring(L, -1);
            timestamp.push_back(file);
            lua_pop(L, 1);
        }
        lua_newtable(L);
        for (auto &&i : timestamp)
        {
            size_t t = std::filesystem::last_write_time(i).time_since_epoch() / std::chrono::milliseconds(1);
            lua_pushstring(L, i.c_str());
            lua_pushinteger(L, t);
            lua_settable(L, -3);
        }
        return 1;
    }
    int GetFileLastModifiedTimestamp(lua_State *L)
    {
        const char *file = lua_tostring(L, 1);
        size_t timestamp = std::filesystem::last_write_time(file).time_since_epoch() / std::chrono::milliseconds(1);
        lua_pushinteger(L, timestamp);
        return 1;
    }

    int Lua_GetFilesInFolder(lua_State *L)
    {
        std::filesystem::path folder(lua_tostring(L, 1));
        size_t j = lua_rawlen(L, 2);
        std::unordered_set<std::string> exclude;
        for (size_t i = 1; i <= j; i++)
        {
            lua_rawgeti(L, 2, i);
            exclude.insert(lua_tostring(L, -1));
            lua_pop(L, 1);
        }
        lua_newtable(L);
        GetFilesInFolder(L, folder, exclude);

        return 1;
    }

    void GetFilesInFolder(lua_State *L, std::filesystem::path folder, std::unordered_set<std::string> &exclude)
    {

        for (auto &&directoryOrFile : std::filesystem::directory_iterator(folder))
        {
            if (directoryOrFile.is_directory())
            {
                if (exclude.find(directoryOrFile.path().filename().string()) == exclude.end())
                    GetFilesInFolder(L, directoryOrFile, exclude);
            }
            else
            {
                lua_pushinteger(L, lua_rawlen(L, -1) + 1);
                lua_pushstring(L, directoryOrFile.path().string().c_str());
                lua_settable(L, -3);
            }
        }
    }
    int DeleteFile(lua_State *L)
    {
        remove(lua_tostring(L, 1));
        return 0;
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

    int CopyFileMultiThreads(lua_State *L)
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

            lua_pop(L, 1); // 把栈顶的值移出栈,让key成为栈顶以便继续遍历
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

    int CopyFile(lua_State *L)
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

    int GetFileMd5(lua_State *L)
    {
        const char *file = lua_tostring(L, 1);
        lua_pushstring(L, getFileMD5(file).c_str());
        return 1;
    }

    int IsFileExist(lua_State *L)
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
        std::cout << lua_typename(L, lua_type(L, -1)) << std::endl;
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

}
