#Requires AutoHotkey v2.0

; ========================================================
; 模块：纯文本粘贴 (Win+V)
; 功能：模仿 PureText，按 Win+V 时粘贴去除格式后的纯文本
; 原理：备份剪贴板 -> 剪贴板只保留纯文本 -> 模拟Ctrl+V -> 恢复原剪贴板
; ========================================================
class PureTextPasteModule extends ModuleBase {

    __New() {
        this.Name := "纯文本粘贴(Win+V)"
        this.Priority := 150      ; 启动顺序，排在现有模块之后即可
        this.MenuOrder := 45      ; 菜单排在 夜间自动降低音量(40) 之后
        this.MenuGroup := 1       ; 和其他"开关式"功能同组
        this.ShowInMenu := true
        this.ContributesToMenu := true
        this.MenuIcon := ["shell32.dll", 176]   ; 剪贴板相关图标，可自行更换
    }

    Init() {
        ; 注册 Win+V 热键，绑定到本模块的 DoPaste 方法
        Hotkey("#v", ObjBindMethod(this, "DoPaste"))

        ; 如果模块初始就是关闭状态，立即把热键关掉，
        ; 让系统原生的 Win+V 剪贴板历史生效
        if (!this.Enabled)
            Hotkey("#v", , "Off")
    }

    ; 开关切换时：真正启用/禁用这个热键本身，
    ; 而不是仅仅改内部标志位——这样关闭时系统自带的 Win+V 才能正常弹出
    OnToggle() {
        Hotkey("#v", , this.Enabled ? "On" : "Off")
    }

    DoPaste(*) {
        ; 备份当前剪贴板（含所有格式：富文本/HTML/图片/文件等）
        clipBackup := ClipboardAll()

        ; 读取纯文本内容（AHK 读取 A_Clipboard 时天然是纯文本表示）
        plainText := A_Clipboard

        ; 如果剪贴板里没有文本内容（比如纯图片/文件），
        ; 直接走普通粘贴，不做任何处理
        if (plainText = "") {
            Send("^v")
            return
        }

        ; 清空剪贴板，再只塞入纯文本，去掉其余格式信息
        A_Clipboard := ""
        A_Clipboard := plainText

        ; 等待剪贴板真正写入完成（最多等1秒），避免粘贴到空内容
        if !ClipWait(1) {
            A_Clipboard := clipBackup
            return
        }

        ; 模拟 Ctrl+V 完成粘贴动作
        Send("^v")

        ; 300ms 后异步恢复原始剪贴板内容，
        ; 避免恢复过早导致目标程序还没来得及读取新内容就被换回去
        SetTimer(() => this.RestoreClipboard(clipBackup), -300)
    }

    RestoreClipboard(backup) {
        A_Clipboard := backup
    }
}

ModuleRegistry.Register(PureTextPasteModule())