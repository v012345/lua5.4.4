cmake_minimum_required(VERSION 3.20.0)
project(imGuiBackends)
add_library(imGuiBackends STATIC imgui_impl_win32.cpp imgui_impl_dx12.cpp)
include_directories(..)
