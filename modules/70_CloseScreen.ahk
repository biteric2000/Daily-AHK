; ════════════════════════════════════════════════════════════════
; 文件: modules/70_CloseScreen.ahk
; ════════════════════════════════════════════════════════════════

class CloseScreenModule extends ModuleBase {
    __New() {
        this.Name := "立即关闭屏幕"
        this.Priority := 70
        this.MenuOrder := 50     ; 还原到原来位置（音量组之后）
        this.MenuGroup := 2
        this.ShowInMenu := false
        this.ScreenIsOff := false
    }

    Init() {
        Hotkey("^!o", ObjBindMethod(this, "CloseScreenNow"))
    }

    BuildMenu(trayMenu) {
        trayMenu.Add("立即关闭屏幕", ObjBindMethod(this, "CloseScreenNow"))
        trayMenu.SetIcon("立即关闭屏幕", "shell32.dll", 110)
    }

    CloseScreenNow(*) {
        PostMessage(0x0112, 0xF170, 2, , "Program Manager")
        this.ScreenIsOff := true
    }
}

ModuleRegistry.Register(CloseScreenModule())
