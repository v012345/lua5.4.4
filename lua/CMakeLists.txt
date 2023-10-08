cmake_minimum_required(VERSION 3.20)
project(lualib)
add_definitions(-DLUA_BUILD_AS_DLL)

add_library(lualib SHARED
    lapi.c
    lauxlib.c
    lbaselib.c
    lcode.c
    lcorolib.c
    lctype.c
    ldblib.c
    ldebug.c
    ldo.c
    ldump.c
    lfunc.c
    lgc.c
    linit.c
    liolib.c
    llex.c
    lmathlib.c
    lmem.c
    loadlib.c
    lobject.c
    lopcodes.c
    loslib.c
    lparser.c
    lstate.c
    lstring.c
    lstrlib.c
    ltable.c
    ltablib.c
    ltm.c

    # lua.c
    # luac.c
    lundump.c
    lutf8lib.c
    lvm.c
    lzio.c
)

# add_executable(lua lua.c)
# target_link_libraries(lua lualib)

# add_executable(luac luac.c)
# target_link_libraries(luac lualib)
