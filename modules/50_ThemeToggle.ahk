; ════════════════════════════════════════════════════════════════
; 文件: modules/50_ThemeToggle.ahk
; ════════════════════════════════════════════════════════════════

class ThemeToggleModule extends ModuleBase {
    __New() {
        this.Name := "主题切换"
        this.Priority := 50
        this.MenuOrder := 70
        this.MenuGroup := 4
    }

    Init() {
        Hotkey("^!d", ObjBindMethod(this, "Toggle"))
        OnMessage(0x404, ObjBindMethod(this, "TrayIconMsg"))

        ; 预先取出 uxtheme.dll 里几个未公开函数的指针（按序号取址）
        ; 注意：AHK 的 DllCall 不支持 "dll\#序号" 这种简写语法，
        ; 必须先用 GetProcAddress 拿到函数指针，再用指针去调用
        hUxtheme := DllCall("LoadLibrary", "Str", "uxtheme.dll", "Ptr")
        this.pSetPreferredAppMode := DllCall("GetProcAddress", "Ptr", hUxtheme, "Ptr", 135, "Ptr")
        this.pFlushMenuThemes     := DllCall("GetProcAddress", "Ptr", hUxtheme, "Ptr", 136, "Ptr")
        this.pRefreshImmersiveColorPolicyState := DllCall("GetProcAddress", "Ptr", hUxtheme, "Ptr", 104, "Ptr")

        ; 让原生弹出菜单（包括托盘右键菜单）感知系统深色模式
        this.EnableDarkMenus()
    }

    EnableDarkMenus() {
        try {
            DllCall(this.pSetPreferredAppMode, "Int", 1)         ; 允许深色渲染
            DllCall(this.pRefreshImmersiveColorPolicyState)      ; 刷新沉浸式颜色策略
            DllCall(this.pFlushMenuThemes)                        ; 让弹出菜单立即按新状态重新渲染
        }
    }

    BuildMenu(trayMenu) {
        trayMenu.Add("切换为浅色模式", (*) => this.SetTheme(true))
        trayMenu.Add("切换为深色模式", (*) => this.SetTheme(false))
        trayMenu.SetIcon("切换为浅色模式", "shell32.dll", 46)
        trayMenu.SetIcon("切换为深色模式", "shell32.dll", 47)
    }

    TrayIconMsg(wParam, lParam, msg, hwnd) {
        if (lParam = 0x203) {
            this.Toggle()
            return 0
        }
    }

    SetTheme(isLight) {
        value := isLight ? 1 : 0
        RegWrite(value, "REG_DWORD", "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize", "AppsUseLightTheme")
        RegWrite(value, "REG_DWORD", "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize", "SystemUsesLightTheme")

        DllCall("SendMessageTimeout", "ptr", 0xFFFF, "uint", 0x1A, "ptr", 0, "str", "ImmersiveColorSet", "uint", 0x0002, "uint", 1000, "ptr*", 0)

        ; 每次手动切换主题后，重新刷新一遍菜单主题状态
        try {
            DllCall(this.pRefreshImmersiveColorPolicyState)
            DllCall(this.pFlushMenuThemes)
        }
    }

    Toggle(*) {
        current := RegRead("HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize", "AppsUseLightTheme", 1)
        this.SetTheme(current = 0)
    }
}

ModuleRegistry.Register(ThemeToggleModule())
