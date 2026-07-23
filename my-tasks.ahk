#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent
SetKeyDelay(50, 50)

; ========================================================
; ============ 可调参数（按需修改这一区块即可） ============
; ========================================================

; --- 夜间时间段定义（24小时制 HHmm 格式，字符串比较） ---
NightStartTime := "2030"   ; 夜间开始：20:30
NightEndTime   := "0900"   ; 夜间结束：次日 09:00

; --- 强制关屏功能参数 ---
IdleTimeoutMs     := 1800000   ; 无操作多久后关屏，30分钟；测试可改小，如 5000 = 5秒
CheckIntervalMs   := 20000      ; 关屏检测频率（毫秒）

; --- 夜间降音量功能参数 ---
VolumeCheckIntervalMs := 1200000  ; 每20分钟检测一次是否需要降音量

; ========================================================
; ==================== 全局状态变量 =======================
; ========================================================

global ScreenIsOff := false

; ========================================================
; =================== 公用函数：夜间判断 ===================
; ========================================================

IsNightTime() {
    global NightStartTime, NightEndTime
    currentTime := FormatTime(, "HHmm")
    ; 跨越零点，用 or 连接两个条件
    if (currentTime >= NightStartTime or currentTime < NightEndTime)
        return true
    return false
}

; ========================================================
; ================ 功能一：夜间物理闲置关屏 =================
; ========================================================

SetTimer(ForceScreenOffCheck, CheckIntervalMs)

ForceScreenOffCheck() {
    global IdleTimeoutMs, ScreenIsOff

    ; 白天完全不触发，并复位状态，避免影响夜间逻辑
    if (!IsNightTime()) {
        ScreenIsOff := false
        return
    }

    idle := A_TimeIdlePhysical

    if (idle > IdleTimeoutMs) {
        ; 只在"由亮转暗"这一瞬间发送一次关屏命令，避免重复发送
        if (!ScreenIsOff) {
            PostMessage(0x0112, 0xF170, 2, , "Program Manager")
            ScreenIsOff := true
        }
    } else {
        ; 检测到用户操作，说明屏幕已被唤醒，复位状态
        ScreenIsOff := false
    }
}

; ========================================================
; ================ 功能二：夜间自动降低音量 =================
; ========================================================

SetTimer(DecreaseVolumeAtNight, VolumeCheckIntervalMs)

DecreaseVolumeAtNight() {
    if (IsNightTime()) {
        Send("{Volume_Down}")
    }
    ; 不在夜间时段则什么都不做
}

; ========================================================
; ============== 功能三：Copilot 键重定义为右 Ctrl ==============
; ========================================================

; 将 Copilot 键（映射为 F23）改为右 Ctrl
*<+<#f23:: {
    Send("{Blind}{LShift Up}{LWin Up}{RControl Down}")
    KeyWait("F23")
    Send("{RControl up}")
}

; ========================================================
; ======================== 热键区域 ========================
; ========================================================

; 手动立即关闭屏幕：Ctrl + Alt + O（不受夜间限制，随时可用）
^!o:: {
    global ScreenIsOff
    PostMessage(0x0112, 0xF170, 2, , "Program Manager")
    ScreenIsOff := true
}

; 重新加载脚本：Ctrl + Shift + Alt + R
^+!r:: Reload()

; 退出脚本：Ctrl + Alt + Q
^!q:: ExitApp()

; ========================================================
; ======================= 托盘菜单 =========================
; ========================================================

A_TrayMenu.Add("立即关闭屏幕", (*) => (PostMessage(0x0112, 0xF170, 2, , "Program Manager"), ScreenIsOff := true))
A_TrayMenu.Add()  ; 分隔线
A_TrayMenu.Add("查看当前是否为夜间模式", (*) => MsgBox("当前时间：" FormatTime(, "HH:mm") "`n夜间模式：" (IsNightTime() ? "是（功能已启用）" : "否（关屏/降音量已暂停）")))
A_TrayMenu.Add()  ; 分隔线
A_TrayMenu.Add("重新加载脚本", (*) => Reload())
A_TrayMenu.Add("退出脚本", (*) => ExitApp())
