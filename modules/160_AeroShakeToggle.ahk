#Requires AutoHotkey v2.0

; ========================================================
; 模块：Aero Shake 开关（抖动窗口最小化其他窗口）
; 原理：写注册表 DisallowShaking，改动立即生效，无需重启explorer
; 路径：HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced
; 设计说明：无论开启/关闭，都【显式写入 0 或 1】，从不删除该值，
; 避免"某个状态下 key 消失"造成的困惑（0 和 key不存在对系统效果完全等价）
; ========================================================
class AeroShakeToggleModule extends ModuleBase {

    static RegPath := "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    static RegValue := "DisallowShaking"

    __New() {
        this.Name := "Aero Shake(抖动最小化)"
        this.Priority := 160
        this.MenuOrder := 46
        this.MenuGroup := 1
        this.ShowInMenu := true
        this.ContributesToMenu := true
        ; 不设置 MenuIcon，保持纯"打勾/不打勾"样式
    }

    Init() {
        ; 只读取注册表当前真实状态同步到 Enabled，绝不在此处写入注册表
        this.SyncFromRegistry()
    }

    ; 读取注册表当前真实值，同步到 this.Enabled（不产生任何写操作）
    SyncFromRegistry() {
        val := 0
        try {
            val := RegRead(AeroShakeToggleModule.RegPath, AeroShakeToggleModule.RegValue)
        } catch {
            val := 0   ; 键不存在 = 系统默认 = Aero Shake 开启
        }
        this.Enabled := (val != 1)
    }

    ; 用户点击托盘菜单切换开关时触发，此时才真正写注册表
    OnToggle() {
        this.ApplyState()
    }

    ; 把 this.Enabled 的值显式写入注册表，永远是"写值"，不再有"删除"分支
    ApplyState() {
        try {
            writeVal := this.Enabled ? 0 : 1
            RegWrite(writeVal, "REG_DWORD", AeroShakeToggleModule.RegPath, AeroShakeToggleModule.RegValue)
        } catch as e {
            TrayTip("Aero Shake 设置失败", e.Message, 3)
        }
    }
}

ModuleRegistry.Register(AeroShakeToggleModule())