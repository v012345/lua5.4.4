#include <lua.hpp>
#include <string>
#include <vector>
class Communicator
{
private:
    /* data */
    lua_State *L = nullptr;
    std::vector<std::string> outputs;

public:
    Communicator(std::string);
    ~Communicator();
    void update();
    void compare();
    std::vector<std::string> getOutputs();
    int updateOutputBuffer(lua_State *L);
};