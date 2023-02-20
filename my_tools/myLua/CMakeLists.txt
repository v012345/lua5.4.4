cmake_minimum_required(VERSION 3.20)
project(myLua)
add_executable(${PROJECT_NAME} main.cpp src/nightowl_c_api.cpp src/nightowl_c_xml.cpp)
target_include_directories(${PROJECT_NAME} PRIVATE include)
target_include_directories(${PROJECT_NAME} PRIVATE ${CMAKE_SOURCE_DIR}/lua/src)
target_include_directories(${PROJECT_NAME} PRIVATE ${CMAKE_SOURCE_DIR}/libs/CalculateMd5/include)
target_link_libraries(${PROJECT_NAME} lualib CalculateMd5 pugixml::pugixml)
target_compile_features(${PROJECT_NAME} PRIVATE cxx_std_20)

message("------------------- ${CMAKE_SOURCE_DIR} -------------------")
add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_directory
    ${CMAKE_SOURCE_DIR}/scripts/lua
    ${CMAKE_CURRENT_BINARY_DIR}/Debug)
    message("------------------- ${CMAKE_CURRENT_BINARY_DIR} -------------------")
add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_directory
    ${CMAKE_SOURCE_DIR}/scripts/lua
    ${CMAKE_CURRENT_BINARY_DIR}/Release)


