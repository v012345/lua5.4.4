cmake_minimum_required(VERSION 3.20)
project(test)
add_compile_definitions(
    LUA_SCRIPTS="${CMAKE_CURRENT_SOURCE_DIR}/?.lua"
    LUA_MAIN_ENTRY="${CMAKE_CURRENT_SOURCE_DIR}/test.lua"
    LUA_AUX_LIB="${CMAKE_CURRENT_SOURCE_DIR}/Global.lua"
)
add_executable(${PROJECT_NAME} test.c auxlib.c)

target_include_directories(${PROJECT_NAME} PRIVATE ${CMAKE_SOURCE_DIR}/lua)
target_include_directories(${PROJECT_NAME} PRIVATE ${CMAKE_SOURCE_DIR}/modules)
target_link_libraries(${PROJECT_NAME} lualib lfs)