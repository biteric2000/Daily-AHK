; ════════════════════════════════════════════════════════════════
; 文件: modules/20_CopilotRemap.ahk
; ════════════════════════════════════════════════════════════════

class CopilotRemapModule extends ModuleBase {
    __New() {
        this.Name := "Copilot键重映射"
        this.Priority := 20
        this.MenuOrder := 20     ; 还原到原来第2位
        this.MenuGroup := 1
        this.MenuIcon := ["shell32.dll", 269]
    }

    Init() {
        Hotkey("*<+<#f23", ObjBindMethod(this, "OnCopilotKey"))
    }

    OnCopilotKey(*) {
        if (!this.Enabled)
            return
        Send("{Blind}{LShift Up}{LWin Up}{RControl Down}")
        KeyWait("F23")
        Send("{RControl up}")
    }

    OnToggle() {
        Hotkey("*<+<#f23", this.Enabled ? "On" : "Off")
    }
}

ModuleRegistry.Register(CopilotRemapModule())
