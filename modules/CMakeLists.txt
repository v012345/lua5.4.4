cmake_minimum_required(VERSION 3.20)
project(modules)
add_library(lfs SHARED lfs.c)
target_include_directories(lfs PRIVATE ${CMAKE_SOURCE_DIR}/lua)
target_link_libraries(lfs lualib)

add_library(lno SHARED lno.c)
target_include_directories(lno PRIVATE ${CMAKE_SOURCE_DIR}/lua)
target_link_libraries(lno lualib)