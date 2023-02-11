cmake_minimum_required(VERSION 3.20.0)
project(imGui)
add_subdirectory(backends)
add_executable(${PROJECT_NAME}
    main.cpp
    imgui.cpp
    imgui_demo.cpp
    imgui_draw.cpp
    imgui_widgets.cpp
    imgui_tables.cpp
)

target_include_directories(${PROJECT_NAME} PUBLIC backends)
target_link_libraries(${PROJECT_NAME} PUBLIC imGuiBackends d3d12.lib dxgi.lib)
