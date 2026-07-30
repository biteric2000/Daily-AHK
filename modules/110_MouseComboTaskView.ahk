#Requires AutoHotkey v2.0

class MouseComboTaskViewModule extends ModuleBase {
    __New() {
        this.Name := "鼠标右键+中键→任务视图"
        this.Priority := 110
        this.MenuOrder := 100
        this.MenuGroup := 1
        this.ShowInMenu := false
        this.ContributesToMenu := false
        this.suppressMButton := false
    }

    Init() {
        ; 右键本身永远不注册热键，保持 100% 原生行为
        Hotkey("MButton", ObjBindMethod(this, "OnMButtonDown"), "On")
        Hotkey("MButton Up", ObjBindMethod(this, "OnMButtonUp"), "On")
    }

    OnMButtonDown(*) {
        if (GetKeyState("RButton", "P")) {
            this.suppressMButton := true

            ; 临时挂钩一次右键“松开”事件：
            ; 触发组合键时右键仍处于物理按下状态，稍后你松开右键这个动作
            ; 会被刚弹出的任务切换界面误判成一次右键点击（弹出贴靠/移动菜单）。
            ; 这里拦截这一次“迟到”的松开事件，不让它传给任务切换界面。
            Hotkey("RButton Up", ObjBindMethod(this, "SwallowRButtonUp"), "On")
            SetTimer(ObjBindMethod(this, "SafetyRestoreRButton"), -1500)

            Send("#{Tab}")
        } else {
            this.suppressMButton := false
            Send("{MButton down}")
        }
    }

    OnMButtonUp(*) {
        if (!this.suppressMButton)
            Send("{MButton up}")
        this.suppressMButton := false
    }

    SwallowRButtonUp(*) {
        Hotkey("RButton Up", "Off")

        ; 关键修复：刚才这次释放被吞掉后，Windows 会认为右键仍“悬空按下”，
        ; 导致之后第一次正常右键点击其实是在补齐这次缺失的释放动作
        ; （表现为“要点两次才正常”）。
        ; 这里把光标瞬移到屏幕外补发一次真实的释放事件（屏幕外无任何窗口
        ; 能响应，不会弹出菜单），随后立刻移回原位，全程几毫秒内完成。
        MouseGetPos(&origX, &origY)
        MouseMove(-10000, -10000, 0)
        Send("{RButton up}")
        MouseMove(origX, origY, 0)
    }

    SafetyRestoreRButton(*) {
        try Hotkey("RButton Up", "Off")
    }
}

ModuleRegistry.Register(MouseComboTaskViewModule())
