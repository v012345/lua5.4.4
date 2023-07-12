cmake_minimum_required(VERSION 3.20)
project(myLua)

add_executable(${PROJECT_NAME} main.cpp)

target_include_directories(${PROJECT_NAME} PRIVATE include)
target_include_directories(${PROJECT_NAME} PRIVATE ${CMAKE_SOURCE_DIR}/lua)
target_include_directories(${PROJECT_NAME} PRIVATE ${CMAKE_SOURCE_DIR}/modules)
target_link_libraries(${PROJECT_NAME} lualib lfs)
target_compile_features(${PROJECT_NAME} PRIVATE cxx_std_20)

message("------------------- ${CMAKE_SOURCE_DIR} -------------------")
set(CMAKE_BUILD_TYPE Release)
set(CMAKE_BUILD_TYPE Debug)
add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_directory
    ${CMAKE_SOURCE_DIR}/scripts/lua
    ${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_BUILD_TYPE})
add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy
    "${CMAKE_SOURCE_DIR}/build/lua/${CMAKE_BUILD_TYPE}/lualib.dll"
    "${CMAKE_SOURCE_DIR}/build/modules/${CMAKE_BUILD_TYPE}/lfs.dll"
    ${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_BUILD_TYPE})
