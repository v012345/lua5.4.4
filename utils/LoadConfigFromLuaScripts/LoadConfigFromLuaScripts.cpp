#include <lua.hpp>
#include <iostream>
#include <filesystem>

static int GetFileLastModifiedTimestamp(lua_State *L);
static int GetFilesInfoInDirectory(lua_State *L);

int main(int argc, char const *argv[])
{
    if (argc > 1 && std::filesystem::exists(argv[1]))
    {
        std::cout << "enter " << argv[1] << std::endl;
        lua_State *L = luaL_newstate();
        luaL_openlibs(L);
        lua_register(L, "GetFileLastModifiedTimestamp", GetFileLastModifiedTimestamp);
        lua_register(L, "GetFilesInfoInDirectory", GetFilesInfoInDirectory);
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
    // const char *directory = lua_tostring(L, 1);
    // lua_newtable(L);
    // std::size_t timestamp = std::filesystem::last_write_time(file).time_since_epoch() / std::chrono::milliseconds(1);
    // lua_pushinteger(L, timestamp);
    std::cout << "GetFilesInfoInDirectory" << std::endl;
    lua_newtable(L);
    size_t i = 1;
    for (auto &&directoryOrFile : std::filesystem::directory_iterator(std::filesystem::path(lua_tostring(L, 1))))
    {
        std::cout << i << std::endl;
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
        }
        lua_settable(L, -3);
        i++;
    }

    // lua_newtable(L);
    // for (size_t i = 0; i < 3; i++)
    // {
    //     lua_pushinteger(L, i + 1);
    //     //  lua_pushstring(L, "kkkk");
    //     lua_newtable(L);
    //     for (size_t i = 0; i < 1; i++)
    //     {
    //         lua_pushstring(L, "kkkk");
    //         lua_pushstring(L, "ssss");
    //         lua_settable(L, -3);
    //     }
    //     lua_settable(L, -3);
    // }

    return 1;
}
