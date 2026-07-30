#Requires AutoHotkey v2.0

class GameModeIMEBlockModule extends ModuleBase {
    __New() {
        this.Name := "游戏模式(屏蔽输入法切换)"
        this.Priority := 140
        this.MenuOrder := 45
        this.MenuGroup := 1
        this.ShowInMenu := false   ; 自定义菜单渲染，见下方 BuildMenu
        this.ContributesToMenu := true
        this.Enabled := true       ; 框架层含义：模块本身始终加载
        this.GameModeActive := false  ; 用户真正关心的开关状态，默认关闭
    }

    Init() {
        ; 快捷键 Win+Y：始终常驻监听，作为菜单开关的等效入口
        Hotkey("#y", ObjBindMethod(this, "ToggleGameMode"), "On")

        ; 以下热键始终注册但初始为 Off，通过 Hotkey(key,"On"/"Off") 动态开关
        Hotkey("#Space", ObjBindMethod(this, "BlockWinSpace"), "Off")

        Hotkey("*LShift", ObjBindMethod(this, "OnShiftDown"), "Off")
        Hotkey("*LShift up", ObjBindMethod(this, "OnShiftUp"), "Off")
        Hotkey("*RShift", ObjBindMethod(this, "OnShiftDown"), "Off")
        Hotkey("*RShift up", ObjBindMethod(this, "OnShiftUp"), "Off")
    }

    BuildMenu(trayMenu) {
        trayMenu.Add(this.Name, ObjBindMethod(this, "ToggleGameMode"))
        if (this.GameModeActive)
            trayMenu.Check(this.Name)
    }

    ToggleGameMode(*) {
        this.GameModeActive := !this.GameModeActive
        try A_TrayMenu.ToggleCheck(this.Name)

        state := this.GameModeActive ? "On" : "Off"
        Hotkey("#Space", state)
        Hotkey("*LShift", state)
        Hotkey("*LShift up", state)
        Hotkey("*RShift", state)
        Hotkey("*RShift up", state)

        if (this.GameModeActive)
            TrayTip("游戏模式已开启", "Shift轻点 / Win+空格 切换输入法已屏蔽`n(Win+Y 可快速切换)", 2)
        else
            TrayTip("游戏模式已关闭", "输入法切换热键已恢复正常", 2)
    }

    BlockWinSpace(*) {
        ; 什么都不做 = 彻底吞掉 Win+空格，不让系统触发输入法切换
    }

    OnShiftDown(*) {
        Send("{Blind}{Shift Down}")
    }

    OnShiftUp(*) {
        Send("{Blind}{Shift Up}")
        ; 紧接着发送一个系统未占用的“哑”虚拟键(vk07)，
        ; 打断Windows对“单独轻点Shift”这一模式的识别，从而阻止输入法切换；
        ; 真正的Shift按下/弹起事件已经完整送达系统与游戏，
        ; 不影响 Shift+其他键（如Shift+WASD疾跑、Shift+点击等）的正常使用
        Send("{vk07}")
    }
}

ModuleRegistry.Register(GameModeIMEBlockModule())
