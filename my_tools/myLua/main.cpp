
#include <filesystem>
#include <lua.hpp>
extern "C" {
#include <lfs.h>
}

#define LUA_MAIN_SCRIPT "./main.lua"

int main(int argc, char const* argv[]) {
    lua_State* L = luaL_newstate();
    luaL_openlibs(L);
    luaopen_lfs(L);
    if (std::filesystem::exists(LUA_MAIN_SCRIPT)) { //
        luaL_dofile(L, LUA_MAIN_SCRIPT);
    }
    return 0;
}

// ----------------

// #include <filesystem>
// #include <lua.hpp>
// extern "C" {
// #include <lfs.h>
// }
// #include <windows.h>
// #define LUA_MAIN_SCRIPT "./main.lua"
// HWND g_hButton; // 全局变量，保存按钮句柄
// LRESULT CALLBACK WindowProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam) {
//     switch (uMsg) {
//         case WM_PAINT: {
//             PAINTSTRUCT ps;
//             HDC hdc = BeginPaint(hwnd, &ps);

//             // 设置文本颜色和字体
//             SetTextColor(hdc, RGB(255, 0, 0)); // 设置为红色
//             HFONT hFont = CreateFont(20, 0, 0, 0, FW_NORMAL, FALSE, FALSE, FALSE, DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, DEFAULT_QUALITY, DEFAULT_PITCH | FF_SWISS, "Arial");
//             HFONT hOldFont = (HFONT)SelectObject(hdc, hFont);

//             // 绘制文本
//             RECT rc;
//             GetClientRect(hwnd, &rc);
//             DrawText(hdc, "Hello, World!", -1, &rc, DT_CENTER | DT_VCENTER | DT_SINGLELINE);

//             // 恢复字体和清理资源
//             SelectObject(hdc, hOldFont);
//             DeleteObject(hFont);

//             EndPaint(hwnd, &ps);
//             return 0;
//         }
//         case WM_COMMAND:
//             if (LOWORD(wParam) == BN_CLICKED && (HWND)lParam == g_hButton) { //
//                 MessageBox(hwnd, "Button Clicked!", "Info", MB_OK);
//             }
//             return 0;
//         case WM_DESTROY: //
//             PostQuitMessage(0);
//             return 0;
//         default: //
//             return DefWindowProc(hwnd, uMsg, wParam, lParam);
//     }
// }

// int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow) {
//     // 注册窗口类
//     WNDCLASS wc = {0};
//     wc.lpfnWndProc = WindowProc;
//     wc.hInstance = hInstance;
//     wc.lpszClassName = "MyWindowClass1";
//     RegisterClass(&wc);

//     // 创建窗口
//     HWND hwnd = CreateWindow(wc.lpszClassName, "My Window", WS_OVERLAPPEDWINDOW, CW_USEDEFAULT, CW_USEDEFAULT, 800, 600, NULL, NULL, hInstance, NULL);
//     g_hButton = CreateWindow("BUTTON", "Click Me", WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON, 50, 50, 100, 30, hwnd, NULL, hInstance, NULL);
//     // 显示窗口
//     ShowWindow(hwnd, nCmdShow);

//     // 消息循环
//     MSG msg;
//     while (GetMessage(&msg, NULL, 0, 0)) {
//         TranslateMessage(&msg);
//         DispatchMessage(&msg);
//     }
//     lua_State* L = luaL_newstate();
//     luaL_openlibs(L);
//     luaopen_lfs(L);
//     if (std::filesystem::exists(LUA_MAIN_SCRIPT)) { //
//         luaL_dofile(L, LUA_MAIN_SCRIPT);
//     }
//     return 0;
// }