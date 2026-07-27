; ════════════════════════════════════════════════════════════════
; 文件: modules/40_NumLockReverse.ahk
; ════════════════════════════════════════════════════════════════

class NumLockReverseModule extends ModuleBase {
    __New() {
        this.Name := "NumLock状态反转"
        this.Priority := 40
        this.MenuOrder := 30     ; 还原到原来第3位
        this.MenuGroup := 1
        this.MenuIcon := ["shell32.dll", 234]
        this.KeyMap := Map(
            "Numpad0", "{Ins}", "Numpad1", "{End}", "Numpad2", "{Down}",
            "Numpad3", "{PgDn}", "Numpad4", "{Left}", "Numpad5", "{Clear}",
            "Numpad6", "{Right}", "Numpad7", "{Home}", "Numpad8", "{Up}",
            "Numpad9", "{PgUp}", "NumpadDot", "{Del}",
            "NumpadIns", "0", "NumpadEnd", "1", "NumpadDown", "2",
            "NumpadPgDn", "3", "NumpadLeft", "4", "NumpadClear", "5",
            "NumpadRight", "6", "NumpadHome", "7", "NumpadUp", "8",
            "NumpadPgUp", "9", "NumpadDel", "."
        )
    }

    Init() {
        for keyName, sendValue in this.KeyMap
            Hotkey(keyName, ObjBindMethod(this, "OnNumpadKey", sendValue))
        SetNumLockState("Off")
    }

    OnNumpadKey(sendValue, *) {
        if (this.Enabled)
            Send(sendValue)
    }

    OnToggle() {
        for keyName, sendValue in this.KeyMap
            Hotkey(keyName, this.Enabled ? "On" : "Off")
    }
}

ModuleRegistry.Register(NumLockReverseModule())
