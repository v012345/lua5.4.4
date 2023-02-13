cmake_minimum_required(VERSION 3.20.0)
project(imGui)
add_subdirectory(backends)
add_executable(${PROJECT_NAME}

    # main.cpp
    debug_gui.cpp
    imgui.cpp
    imgui_demo.cpp
    imgui_draw.cpp
    imgui_widgets.cpp
    lua_main.cpp
    imgui_tables.cpp
)

target_include_directories(${PROJECT_NAME} PUBLIC backends)
target_include_directories(${PROJECT_NAME} PRIVATE ${CMAKE_SOURCE_DIR}/lua/src)
target_include_directories(${PROJECT_NAME} PRIVATE ${CMAKE_SOURCE_DIR}/libs/CalculateMd5/include)
target_link_libraries(${PROJECT_NAME} PUBLIC imGuiBackends d3d12.lib dxgi.lib lualib CalculateMd5)
target_compile_features(${PROJECT_NAME} PRIVATE cxx_std_20)
