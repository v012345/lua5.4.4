cmake_minimum_required(VERSION 3.20)
project(test)
# message(${CMAKE_CURRENT_SOURCE_DIR})
add_compile_definitions(
    LUA_SCRIPTS="${CMAKE_CURRENT_SOURCE_DIR}/test.lua"
)
add_executable(${PROJECT_NAME} test.c)

target_include_directories(${PROJECT_NAME} PRIVATE ${CMAKE_SOURCE_DIR}/lua)
target_include_directories(${PROJECT_NAME} PRIVATE ${CMAKE_SOURCE_DIR}/modules)
target_link_libraries(${PROJECT_NAME} lualib lfs)