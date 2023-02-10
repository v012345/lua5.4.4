cmake_minimum_required(VERSION 3.20.0)
project(CalculateMd5)
add_library(CalculateMd5 STATIC src/md5.cpp src/md5file.cpp)
include_directories("include")
