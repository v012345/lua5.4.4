cmake_minimum_required(VERSION 3.20)
project(ToolSets)
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
add_subdirectory("lua")
# add_subdirectory("libs")

# add_subdirectory("utils")
# add_subdirectory("gui")
add_subdirectory("modules")

# add_subdirectory("my_tools")
add_subdirectory("test")
