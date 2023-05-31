cmake_minimum_required(VERSION 3.20)
project(modules VERSION 1.0.0)

# # 设置生成的动态链接库的名称和源文件
add_library(lfs SHARED lfs.c)
target_include_directories(lfs PRIVATE ${CMAKE_SOURCE_DIR}/lua/src)
target_link_libraries(lfs PRIVATE lualib)
# target_link_libraries(lfs lualib)

# 设置导出符号（可选）
# target_compile_definitions(YourLibraryName PRIVATE YOUR_LIBRARY_SYMBOLS)

# 设置其他编译选项（可选）
# target_compile_options(YourLibraryName PRIVATE -Wall -Wextra)

# 设置输出目录（可选）
# set_target_properties(YourLibraryName PROPERTIES LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/output")

# 设置导出的头文件路径（可选）
# target_include_directories(YourLibraryName PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include)