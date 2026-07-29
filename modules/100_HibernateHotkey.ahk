#Requires AutoHotkey v2.0

class HibernateHotkeyModule extends ModuleBase {
    __New() {
        this.Name := "立即休眠"
        this.Priority := 100
        this.MenuOrder := 100
        this.MenuGroup := 1
        this.ShowInMenu := false
        this.ContributesToMenu := false
    }

    Init() {
        Hotkey("#w", ObjBindMethod(this, "DoHibernate"), "On")
    }

    DoHibernate(*) {
        ; 调用系统电源管理API直接进入休眠
        ; 参数：Hibernate=1, Force=0（不强制关闭未响应程序）, DisableWakeEvent=0
        DllCall("PowrProf.dll\SetSuspendState", "Int", 1, "Int", 0, "Int", 0)
    }
}

ModuleRegistry.Register(HibernateHotkeyModule())
