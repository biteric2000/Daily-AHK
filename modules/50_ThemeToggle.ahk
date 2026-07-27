; ════════════════════════════════════════════════════════════════
; 文件: modules/50_ThemeToggle.ahk
; ════════════════════════════════════════════════════════════════

class ThemeToggleModule extends ModuleBase {
    __New() {
        this.Name := "主题切换"
        this.Priority := 50
        this.MenuOrder := 70     ; 还原到原来倒数第2组（浅色/深色按钮）
        this.MenuGroup := 4
    }

    Init() {
        Hotkey("^!d", ObjBindMethod(this, "Toggle"))
    }

    BuildMenu(trayMenu) {
        trayMenu.Add("切换为浅色模式", (*) => this.SetTheme(true))
        trayMenu.Add("切换为深色模式", (*) => this.SetTheme(false))
        trayMenu.SetIcon("切换为浅色模式", "shell32.dll", 46)
        trayMenu.SetIcon("切换为深色模式", "shell32.dll", 47)
    }

    SetTheme(isLight) {
        value := isLight ? 1 : 0
        RegWrite(value, "REG_DWORD", "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize", "AppsUseLightTheme")
        RegWrite(value, "REG_DWORD", "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize", "SystemUsesLightTheme")
        DllCall("SendMessageTimeout", "ptr", 0xFFFF, "uint", 0x1A, "ptr", 0, "str", "ImmersiveColorSet", "uint", 0x0002, "uint", 1000, "ptr*", 0)
    }

    Toggle(*) {
        current := RegRead("HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize", "AppsUseLightTheme", 1)
        this.SetTheme(current = 0)
    }
}

ModuleRegistry.Register(ThemeToggleModule())
