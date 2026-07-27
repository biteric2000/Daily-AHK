; ════════════════════════════════════════════════════════════════
; 文件: modules/90_WindowManager.ahk
; 功能：常用窗口管理 —— 置顶切换 + 移动窗口到下一显示器
; ════════════════════════════════════════════════════════════════

class WindowManagerModule extends ModuleBase {
    __New() {
        this.Name := "窗口管理"
        this.Priority := 90
        this.MenuOrder := 25       ; 建议插在 Copilot 重映射(20)和NumLock(30)之间
        this.MenuGroup := 1
        this.ShowInMenu := false   ; 纯热键驱动，无需菜单开关
        this.ContributesToMenu := false
    }

    Init() {
        Hotkey("^!t", ObjBindMethod(this, "ToggleAlwaysOnTop"))
        Hotkey("^!Right", ObjBindMethod(this, "MoveToNextMonitor"))
    }

    ; Ctrl+Alt+T：切换当前窗口是否置顶
    ToggleAlwaysOnTop(*) {
        WinSetAlwaysOnTop(-1, "A")  ; -1 表示切换当前状态
    }

    ; Ctrl+Alt+→：把当前窗口移动到下一个显示器的相同相对位置
    MoveToNextMonitor(*) {
        hwnd := WinExist("A")
        if (!hwnd)
            return

        monitorCount := MonitorGetCount()
        if (monitorCount < 2)
            return

        WinGetPos(&winX, &winY, &winW, &winH, "A")

        currentMonitor := 0
        Loop monitorCount {
            MonitorGet(A_Index, &left, &top, &right, &bottom)
            if (winX >= left && winX < right) {
                currentMonitor := A_Index
                break
            }
        }
        if (!currentMonitor)
            currentMonitor := 1

        nextMonitor := currentMonitor + 1
        if (nextMonitor > monitorCount)
            nextMonitor := 1

        MonitorGet(currentMonitor, &curLeft, &curTop, &curRight, &curBottom)
        MonitorGet(nextMonitor, &nextLeft, &nextTop, &nextRight, &nextBottom)

        relX := winX - curLeft
        relY := winY - curTop
        newX := nextLeft + relX
        newY := nextTop + relY

        WinMove(newX, newY, winW, winH, "A")
    }
}

ModuleRegistry.Register(WindowManagerModule())