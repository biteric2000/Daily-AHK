; ════════════════════════════════════════════════════════════════
; 文件: modules/60_BacklightAutoOff.ahk
; ════════════════════════════════════════════════════════════════

class BacklightAutoOffModule extends ModuleBase {
    __New() {
        this.Name := "键盘背光自动关闭"
        this.Priority := 60
        this.MenuOrder := 10     ; 还原到原来第1位
        this.MenuGroup := 1
        this.MenuIcon := ["shell32.dll", 152]
        this.LastTriggerTick := 0
        this.DebounceMs := 2000
        this.EnforceCount := 0
        this.ConsecutiveOffCount := 0
        this.hPowerNotify := 0
        this.DebugMode := false

        ; ★ 关键修复：只生成一次绑定函数对象并缓存，
        ; 后续所有 SetTimer 启动/停止都必须复用这同一个引用，
        ; 否则 SetTimer(..., 0) 无法命中之前启动的定时器，会导致
        ; 定时器永久无法停止（表现为背光被无限循环强制关闭）。
        this.EnforceFn := ObjBindMethod(this, "EnforceBacklightOff")
    }

    Init() {
        this.RegisterDisplayStateNotify()
        OnMessage(0x0218, ObjBindMethod(this, "OnDisplayPowerBroadcast"))
        OnExit(ObjBindMethod(this, "OnScriptExit"))
    }

    OpenBacklightDevice() {
        return DllCall("CreateFileW", "str", "\\.\EnergyDrv", "uint", 0x80000000, "uint", 0, "ptr", 0, "uint", 3, "uint", 0x80, "ptr", 0, "ptr")
    }

    DeviceIoControlCall(hDevice, func) {
        inBuf := Buffer(4)
        NumPut("UInt", func, inBuf, 0)
        outBuf := Buffer(4)
        bytesReturned := 0
        result := DllCall("DeviceIoControl", "ptr", hDevice, "uint", 0x83102144, "ptr", inBuf, "uint", 4, "ptr", outBuf, "uint", 4, "uint*", &bytesReturned, "ptr", 0)
        if (!result)
            return -1
        return NumGet(outBuf, 0, "UInt")
    }

    GetCurrentBacklightLevel(hDevice) {
        status := this.DeviceIoControlCall(hDevice, 0x32)
        if (status = -1 || (status & 1) != 1)
            return -1
        status := status >> 1
        return status & 0x7fff
    }

    SetBacklightOff(hDevice) {
        return this.DeviceIoControlCall(hDevice, 0x00033) != -1
    }

    RegisterDisplayStateNotify() {
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
        this.hPowerNotify := DllCall("RegisterPowerSettingNotification", "ptr", A_ScriptHwnd, "ptr", GuidBuf, "uint", 0, "ptr")
    }

    OnDisplayPowerBroadcast(wParam, lParam, msg, hwnd) {
        if (wParam = 0x8013) {
            displayState := NumGet(lParam, 20, "UChar")
            if (displayState = 1)
                this.HandleDisplayOn()
        }
    }

    OnScriptExit(*) {
        if (this.hPowerNotify)
            DllCall("UnregisterPowerSettingNotification", "ptr", this.hPowerNotify)
        SetTimer(this.EnforceFn, 0)   ; ★ 复用缓存的引用
    }

    HandleDisplayOn() {
        if (!this.Enabled)
            return
        if (A_TickCount - this.LastTriggerTick < this.DebounceMs)
            return
        this.LastTriggerTick := A_TickCount
        this.EnforceCount := 0
        this.ConsecutiveOffCount := 0
        SetTimer(this.EnforceFn, 250)   ; ★ 复用缓存的引用
    }

    EnforceBacklightOff() {
        this.EnforceCount++
        hDevice := this.OpenBacklightDevice()
        if (hDevice = -1 || hDevice = 0) {
            SetTimer(this.EnforceFn, 0)   ; ★ 复用缓存的引用
            return
        }
        currentLevel := this.GetCurrentBacklightLevel(hDevice)
        if (currentLevel = 0) {
            this.ConsecutiveOffCount++
        } else {
            this.SetBacklightOff(hDevice)
            this.ConsecutiveOffCount := 0
        }
        DllCall("CloseHandle", "ptr", hDevice)
        if (this.ConsecutiveOffCount >= 2 || this.EnforceCount >= 12) {
            SetTimer(this.EnforceFn, 0)   ; ★ 复用缓存的引用
            if (this.DebugMode)
                TrayTip("背光已确认关闭", "共检测/执行 " this.EnforceCount " 次", 1)
        }
    }
}

ModuleRegistry.Register(BacklightAutoOffModule())