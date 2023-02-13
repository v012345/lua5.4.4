#include <lua.hpp>
#include <lua.hpp>
#include <string>
class lua_main
{
private:
    /* data */
    lua_State *L = nullptr;

public:
    lua_main(std::string);
    ~lua_main();
    void update();
    void compare();
};