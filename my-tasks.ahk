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

; --- 夜间音量自动降低的下限（百分比，低于此值停止继续降低） ---
MinVolumePercent := 3

; --- 强制关屏功能参数 ---



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


; ========================================================
; ================ 功能二：夜间自动降低音量 =================
; ========================================================

SetTimer(DecreaseVolumeAtNight, VolumeCheckIntervalMs)

DecreaseVolumeAtNight() {
    global MinVolumePercent

    if (!IsNightTime())
        return

    currentVolume := SoundGetVolume()

    if (currentVolume > MinVolumePercent)
        Send("{Volume_Down}")
    ; 已经低于等于阈值，则什么都不做，避免继续降低或产生静音提示音
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
; ============== 功能四：自启动鼠标控制程序 ==============
; ========================================================

; 启动程序并等待窗口出现后自动最小化
Run('"C:\Program Files\Highresolution Enterprises\X-Mouse Button Control\XMouseButtonControl.exe"')


; ============================================
; 功能五：NumLock灯状态互换
; NumLock 灯灭 = 数字模式
; NumLock 灯亮 = 方向/编辑模式
; ============================================

; --- NumLock【开】(灯亮) 时物理键发出 Numpad0~9/NumpadDot 信号 ---
; 转发成方向/编辑功能
Numpad0::Send("{Ins}")
Numpad1::Send("{End}")
Numpad2::Send("{Down}")
Numpad3::Send("{PgDn}")
Numpad4::Send("{Left}")
Numpad5::Send("{Clear}")
Numpad6::Send("{Right}")
Numpad7::Send("{Home}")
Numpad8::Send("{Up}")
Numpad9::Send("{PgUp}")
NumpadDot::Send("{Del}")

; --- NumLock【关】(灯灭) 时物理键发出 NumpadIns/NumpadEnd 等信号 ---
; 转发成数字
NumpadIns::Send("0")
NumpadEnd::Send("1")
NumpadDown::Send("2")
NumpadPgDn::Send("3")
NumpadLeft::Send("4")
NumpadClear::Send("5")
NumpadRight::Send("6")
NumpadHome::Send("7")
NumpadUp::Send("8")
NumpadPgUp::Send("9")
NumpadDel::Send(".")

; 加减乘除、Enter 两种状态下功能相同，不受影响，无需处理

; 开机默认让 NumLock 保持关闭（灯灭 + 数字模式）
SetNumLockState("Off")

; 如果想彻底禁用物理 NumLock 键的切换能力，改成下面这行：
; SetNumLockState("AlwaysOff")


; ========================================================
; ============== 功能五：一键切换浅色/深色模式 ==============
; ========================================================

; --- 设置为指定模式：isLight = true 浅色，false 深色 ---
SetWindowsTheme(isLight) {
    value := isLight ? 1 : 0
    RegWrite(value, "REG_DWORD", "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize", "AppsUseLightTheme")
    RegWrite(value, "REG_DWORD", "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize", "SystemUsesLightTheme")

    ; 广播消息，让资源管理器/任务栏实时刷新，无需重启
    DllCall("SendMessageTimeout"
        , "ptr", 0xFFFF          ; HWND_BROADCAST
        , "uint", 0x1A           ; WM_SETTINGCHANGE
        , "ptr", 0
        , "str", "ImmersiveColorSet"
        , "uint", 0x0002         ; SMTO_ABORTIFHUNG
        , "uint", 1000
        , "ptr*", 0)
}

; --- 一键反转当前模式（浅色变深色，深色变浅色）---
ToggleWindowsTheme(*) {
    current := RegRead("HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize", "AppsUseLightTheme", 1)
    SetWindowsTheme(current = 0)  ; 如果当前是深色(0)，则切换为浅色(true)
}


; ========================================================
; ===功能六：显示器唤醒后智能关闭键盘背光（状态确认+提前退出 ======
; ========================================================

global LastTriggerTick2 := 0
global DebounceMs2 := 2000
global EnforceCount := 0
global ConsecutiveOffCount := 0
global hPowerNotify := 0
global DebugMode := false  ; 调试完成后设为 false，关闭多余弹窗

; --- 打开驱动句柄（复用，减少开销）---
OpenBacklightDevice() {
    return DllCall("CreateFileW", "str", "\\.\EnergyDrv", "uint", 0x80000000, "uint", 0, "ptr", 0, "uint", 3, "uint", 0x80, "ptr", 0, "ptr")
}

; --- 通用驱动指令调用 ---
DeviceIoControlCall(hDevice, func) {
    inBuf := Buffer(4)
    NumPut("UInt", func, inBuf, 0)
    outBuf := Buffer(4)
    bytesReturned := 0

    result := DllCall("DeviceIoControl"
        , "ptr", hDevice
        , "uint", 0x83102144
        , "ptr", inBuf, "uint", 4
        , "ptr", outBuf, "uint", 4
        , "uint*", &bytesReturned
        , "ptr", 0)

    if (!result)
        return -1
    return NumGet(outBuf, 0, "UInt")
}

; --- 查询当前背光档位：返回 0/1/2/3，失败返回 -1 ---
GetCurrentBacklightLevel(hDevice) {
    status := DeviceIoControlCall(hDevice, 0x32)
    if (status = -1 || (status & 1) != 1)
        return -1
    status := status >> 1
    return status & 0x7fff  ; 0=关闭 1=低亮 2=高亮 3=智能
}

; --- 设置背光为关闭 ---
SetBacklightOff(hDevice) {
    return DeviceIoControlCall(hDevice, 0x00033) != -1
}

; --- 注册显示器状态监听 ---
RegisterDisplayStateNotify() {
    global hPowerNotify
    GuidBuf := Buffer(16)
    NumPut("UInt",   0x6FE69556, GuidBuf, 0)
    NumPut("UShort", 0x704A,     GuidBuf, 4)
    NumPut("UShort", 0x47A0,     GuidBuf, 6)
    NumPut("UChar",  0x8F, GuidBuf, 8)
    NumPut("UChar",  0x24, GuidBuf, 9)
    NumPut("UChar",  0xC2, GuidBuf, 10)
    NumPut("UChar",  0x8D, GuidBuf, 11)
    NumPut("UChar",  0x93, GuidBuf, 12)
    NumPut("UChar",  0x6F, GuidBuf, 13)
    NumPut("UChar",  0xDA, GuidBuf, 14)
    NumPut("UChar",  0x47, GuidBuf, 15)

    hPowerNotify := DllCall("RegisterPowerSettingNotification", "ptr", A_ScriptHwnd, "ptr", GuidBuf, "uint", 0, "ptr")
}
RegisterDisplayStateNotify()

OnMessage(0x0218, OnDisplayPowerBroadcast)

OnDisplayPowerBroadcast(wParam, lParam, msg, hwnd) {
    if (wParam = 0x8013) {
        displayState := NumGet(lParam, 20, "UChar")
        if (displayState = 1)
            HandleDisplayOn()
    }
}

; --- 脚本退出时的清理逻辑 ---
OnExit(OnScriptExit)

OnScriptExit(*) {
    global hPowerNotify
    if (hPowerNotify)
        DllCall("UnregisterPowerSettingNotification", "ptr", hPowerNotify)
    SetTimer(EnforceBacklightOff, 0)  ; 顺手确保计时器停止，避免退出时残留
    ; 注意：这里不要 return 任何值，保持"隐式返回空"，退出请求才不会被拦截
}


HandleDisplayOn() {
    global LastTriggerTick2, DebounceMs2, EnforceCount, ConsecutiveOffCount

    if (A_TickCount - LastTriggerTick2 < DebounceMs2)
        return
    LastTriggerTick2 := A_TickCount

    EnforceCount := 0
    ConsecutiveOffCount := 0
    SetTimer(EnforceBacklightOff, 250)  ; 每250ms检查+执行一次
}

EnforceBacklightOff() {
    global EnforceCount, ConsecutiveOffCount, DebugMode

    EnforceCount++
    hDevice := OpenBacklightDevice()
    if (hDevice = -1 || hDevice = 0) {
        SetTimer(EnforceBacklightOff, 0)
        return
    }

    currentLevel := GetCurrentBacklightLevel(hDevice)

    if (currentLevel = 0) {
        ; 已经是关闭状态，累计一次"确认关闭"
        ConsecutiveOffCount++
    } else {
        ; 不是关闭状态（被EC重新点亮了），强制关闭一次，重置确认计数
        SetBacklightOff(hDevice)
        ConsecutiveOffCount := 0
    }

    DllCall("CloseHandle", "ptr", hDevice)

    ; 连续2次确认关闭(约500ms稳定无重开)，或超过最大尝试次数(约3秒)，则提前结束
    if (ConsecutiveOffCount >= 2 || EnforceCount >= 12) {
        SetTimer(EnforceBacklightOff, 0)
        if (DebugMode)
            TrayTip("背光已确认关闭", "共检测/执行 " EnforceCount " 次", 1)
    }
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

; 快速反转浅色/深色模式：Ctrl + Alt + D
^!d:: ToggleWindowsTheme()

; 重新加载脚本：Ctrl + Shift + Alt + R
^+!r:: Reload()

; 退出脚本：Ctrl + Alt + Q
^!q:: ExitApp()

; ========================================================
; ======================= 托盘菜单 =========================
; ========================================================

A_TrayMenu.Add()  ; 分隔线
A_TrayMenu.Add("切换为浅色模式", (*) => SetWindowsTheme(true))
A_TrayMenu.Add("切换为深色模式", (*) => SetWindowsTheme(false))
A_TrayMenu.Add("一键反转浅/深色模式", ToggleWindowsTheme)


A_TrayMenu.Add("立即关闭屏幕", (*) => (PostMessage(0x0112, 0xF170, 2, , "Program Manager"), ScreenIsOff := true))
A_TrayMenu.Add()  ; 分隔线
A_TrayMenu.Add("查看当前是否为夜间模式", (*) => MsgBox("当前时间：" FormatTime(, "HH:mm") "`n夜间模式：" (IsNightTime() ? "是（功能已启用）" : "否（关屏/降音量已暂停）")))
A_TrayMenu.Add()  ; 分隔线
A_TrayMenu.Add("重新加载脚本", (*) => Reload())
A_TrayMenu.Add("退出脚本", (*) => ExitApp())
