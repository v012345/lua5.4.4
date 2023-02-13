cmake_minimum_required(VERSION 3.20.0)
project(Gui)
add_executable(${PROJECT_NAME} win32_directx12.cpp Communicator.cpp)

target_include_directories(${PROJECT_NAME} PRIVATE ${CMAKE_SOURCE_DIR}/lua/src)
target_include_directories(${PROJECT_NAME} PRIVATE ${CMAKE_SOURCE_DIR}/libs/DearImGui)
target_include_directories(${PROJECT_NAME} PRIVATE ${CMAKE_SOURCE_DIR}/libs/DearImGui/backends)

target_link_libraries(${PROJECT_NAME} PUBLIC DearImGuiLib DearImGuiBackendsLib d3d12.lib dxgi.lib lualib)
target_compile_features(${PROJECT_NAME} PRIVATE cxx_std_20)
