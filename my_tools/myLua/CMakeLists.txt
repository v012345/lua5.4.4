cmake_minimum_required(VERSION 3.20)
project(myLua)
add_executable(${PROJECT_NAME} main.cpp

    # src/nightowl_c_api.cpp
    # src/god.cpp
    # src/angel.cpp
)
target_include_directories(${PROJECT_NAME} PRIVATE include)
target_include_directories(${PROJECT_NAME} PRIVATE ${CMAKE_SOURCE_DIR}/lua)
target_include_directories(${PROJECT_NAME} PRIVATE ${CMAKE_SOURCE_DIR}/modules)
target_link_libraries(${PROJECT_NAME} lualib lfs)
target_compile_features(${PROJECT_NAME} PRIVATE cxx_std_20)

message("------------------- ${CMAKE_SOURCE_DIR} -------------------")
add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_directory
    ${CMAKE_SOURCE_DIR}/scripts/lua
    ${CMAKE_CURRENT_BINARY_DIR}/Debug)

if(EXISTS "${CMAKE_SOURCE_DIR}/build/lua/Debug/lualib.dll" AND EXISTS "${CMAKE_SOURCE_DIR}/build/modules/Debug/lfs.dll")
    add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy
        "${CMAKE_SOURCE_DIR}/build/lua/Debug/lualib.dll"
        "${CMAKE_SOURCE_DIR}/build/modules/Debug/lfs.dll"
        ${CMAKE_CURRENT_BINARY_DIR}/Debug)
endif()

message("------------------- ${CMAKE_CURRENT_BINARY_DIR} -------------------")
add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_directory
    ${CMAKE_SOURCE_DIR}/scripts/lua
    ${CMAKE_CURRENT_BINARY_DIR}/Release)

if(EXISTS "${CMAKE_SOURCE_DIR}/build/lua/Release/lualib.dll" AND EXISTS "${CMAKE_SOURCE_DIR}/build/modules/Release/lfs.dll")
    add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy
        "${CMAKE_SOURCE_DIR}/build/lua/Release/lualib.dll"
        "${CMAKE_SOURCE_DIR}/build/modules/Release/lfs.dll"
        ${CMAKE_CURRENT_BINARY_DIR}/Release)
endif()
