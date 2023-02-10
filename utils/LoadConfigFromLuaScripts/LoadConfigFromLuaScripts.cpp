#include <lua.hpp>
#include <iostream>
#include <filesystem>

static int GetFileLastModifiedTimestamp(lua_State *L);
static int GetFilesInfoInDirectory(lua_State *L);
static int CopyFile(lua_State *L);

int main(int argc, char const *argv[])
{
    if (argc > 1 && std::filesystem::exists(argv[1]))
    {
        std::cout << "enter " << argv[1] << std::endl;
        lua_State *L = luaL_newstate();
        luaL_openlibs(L);
        lua_register(L, "GetFileLastModifiedTimestamp", GetFileLastModifiedTimestamp);
        lua_register(L, "GetFilesInfoInDirectory", GetFilesInfoInDirectory);
        lua_register(L, "CopyFile", CopyFile);
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
            {
                lua_pushstring(L, "filename");
                lua_pushstring(L, directoryOrFile.path().filename().string().c_str());
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