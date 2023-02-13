#include "Communicator.h"

Communicator::Communicator(std::string lua_file)
{
    this->L = luaL_newstate();
    luaL_openlibs(L);

    luaL_dofile(L, lua_file.c_str());
}

Communicator::~Communicator()
{
    lua_close(L);
}

void Communicator::update()
{
    if (this->L != nullptr)
    {
        auto i = lua_getglobal(L, "update"); // 返回这个东西的类型 ** basic types
        lua_pcall(this->L, 0, 0, 0);
    }
}
int Communicator::updateOutputBuffer(lua_State *L)
{
    return 1;
}

void Communicator::compare()
{
    // lua_register(L, "updateOutputBuffer", &this->updateOutputBuffer);
    if (this->L != nullptr)
    {
        lua_getglobal(L, "add_action");
        lua_pushstring(L, "compare");
        lua_pcall(this->L, 1, 0, 0);
        this->outputs.push_back("sssssssssss");
        // lua_touserdata(L,-1);
    }
}

std::vector<std::string> Communicator::getOutputs()
{
    return this->outputs;
}
