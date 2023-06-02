
// #include <filesystem>
// #include <lua.hpp>
// extern "C" {
// #include <lfs.h>
// }

// #define LUA_MAIN_SCRIPT "./main.lua"

// int main(int argc, char const* argv[]) {
//     lua_State* L = luaL_newstate();
//     luaL_openlibs(L);
//     luaopen_lfs(L);
//     if (std::filesystem::exists(LUA_MAIN_SCRIPT)) { //
//         luaL_dofile(L, LUA_MAIN_SCRIPT);
//     }
//     return 0;
// }

// ----------------

#include <filesystem>
#include <lua.hpp>
extern "C" {
#include <lfs.h>
}
#define UNICODE
#include <windows.h>
#define LUA_MAIN_SCRIPT "./main.lua"

void* Call_Lua(lua_State* L,const char* function_name) {
    lua_getglobal(L, "_Lua_functions"); // 获取函数引用
    lua_getfield(L, -1, function_name);
    lua_remove(L, -2); // 从栈中移除表
    lua_call(L, 0, 0); // 调用函数，1个参数，1个返回值
    return NULL;
}

HWND g_hButton; // 全局变量，保存按钮句柄
lua_State* L;
LRESULT CALLBACK WindowProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam) {
    switch (uMsg) {
        case WM_PAINT: {
            PAINTSTRUCT ps;
            HDC hdc = BeginPaint(hwnd, &ps);
            // 加载字体文件
            AddFontResourceEx(L"C:\\Windows\\Fonts\\simhei.ttf", FR_PRIVATE, 0);
            // 设置文本颜色和字体
            SetTextColor(hdc, RGB(255, 0, 0)); // 设置为红色
            HFONT hFont = CreateFont(16, 0, 0, 0, FW_NORMAL, FALSE, FALSE, FALSE, GB2312_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, DEFAULT_QUALITY, DEFAULT_PITCH | FF_DONTCARE, L"Arial");
            HFONT hOldFont = (HFONT)SelectObject(hdc, hFont);

            // 绘制文本
            RECT rc;
            GetClientRect(hwnd, &rc);
            DrawText(hdc, L"H我ello, World!", -1, &rc, DT_CENTER | DT_VCENTER | DT_SINGLELINE);
            // const char* japaneseText = reinterpret_cast<const char*>(L"aaaaこんにちは、世界！");
            // wchar_t wideText[100];
            // MultiByteToWideChar(CP_UTF8, 0, japaneseText, -1, wideText, sizeof(wideText) / sizeof(wideText[0]));
            // TextOutW(hdc, 10, 10, wideText, lstrlenW(wideText));

            // 恢复字体和清理资源
            SelectObject(hdc, hOldFont);
            DeleteObject(hFont);
            RemoveFontResourceEx(L"C:\\Windows\\Fonts\\simhei.ttf", FR_PRIVATE, 0);
            EndPaint(hwnd, &ps);
            return 0;
        }
        case WM_COMMAND:
            if (LOWORD(wParam) == BN_CLICKED && (HWND)lParam == g_hButton) { //
                // MessageBox(hwnd, "Button Clicked!", "Info", MB_OK);

                Call_Lua(L, "print_time");
                // lua_pushnumber(L, 123); // 传递参数
            }
            return 0;
        case WM_DESTROY: //
            PostQuitMessage(0);
            return 0;
        default: //
            return DefWindowProc(hwnd, uMsg, wParam, lParam);
    }
}

int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow) {
    L = luaL_newstate();
    luaL_openlibs(L);
    luaopen_lfs(L);
    luaL_dofile(L, LUA_MAIN_SCRIPT); //
    // if (std::filesystem::exists(LUA_MAIN_SCRIPT)) { //
    //     // luaL_dofile(L, LUA_MAIN_SCRIPT);
    // }

    // 注册窗口类
    WNDCLASS wc = {0};
    wc.lpfnWndProc = WindowProc;
    wc.hInstance = hInstance;
    wc.lpszClassName = L"MyWindowClass1";
    RegisterClass(&wc);

    // 创建窗口
    HWND hwnd = CreateWindow(wc.lpszClassName, L"My Window", WS_OVERLAPPEDWINDOW, CW_USEDEFAULT, CW_USEDEFAULT, 800, 600, NULL, NULL, hInstance, NULL);
    g_hButton = CreateWindow(L"BUTTON", L"Click Me", WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON, 50, 50, 100, 30, hwnd, NULL, hInstance, NULL);
    // 显示窗口
    ShowWindow(hwnd, nCmdShow);
    // 创建控制台
    AllocConsole();
    FILE* pConsole;
    freopen_s(&pConsole, "CONOUT$", "w", stdout);

    // 消息循环
    MSG msg;
    while (GetMessage(&msg, NULL, 0, 0)) {
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }
    return 0;
}