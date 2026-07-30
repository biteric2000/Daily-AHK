#Requires AutoHotkey v2.0

class XButtonComboAltSpaceModule extends ModuleBase {
    __New() {
        this.Name := "鼠标4键+5键→系统菜单"
        this.Priority := 130
        this.MenuOrder := 100
        this.MenuGroup := 1
        this.ShowInMenu := false
        this.ContributesToMenu := false
    }

    Init() {
        ; 单独按下鼠标4键/5键时，还原为原先经XMBC模拟的 PgUp/PgDn 功能
        ; （原生按键事件被AHK接管后需手动转发，否则会失效）
        Hotkey("XButton1", ObjBindMethod(this, "SendPgUp"), "On")
        Hotkey("XButton2", ObjBindMethod(this, "SendPgDn"), "On")

        ; 双向定义组合键，不论先按哪个键都能触发
        Hotkey("XButton1 & XButton2", ObjBindMethod(this, "TriggerSystemMenu"), "On")
        Hotkey("XButton2 & XButton1", ObjBindMethod(this, "TriggerSystemMenu"), "On")
    }

    SendPgUp(*) {
        Send("{PgUp}")
    }

    SendPgDn(*) {
        Send("{PgDn}")
    }

    TriggerSystemMenu(*) {
        Send("!{Space}")
    }
}

ModuleRegistry.Register(XButtonComboAltSpaceModule())
