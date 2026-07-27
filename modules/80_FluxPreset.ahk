; ════════════════════════════════════════════════════════════════
; 文件: modules/80_FluxPreset.ahk
; ════════════════════════════════════════════════════════════════

class FluxPresetModule extends ModuleBase {
    __New() {
        this.Name := "f.lux 色温预设"
        this.Priority := 80
        this.MenuOrder := 60     ; 还原到原来位置（关屏之后，主题切换之前）
        this.MenuGroup := 3
        this.ShowInMenu := false
        this.RegPath := "HKCU\Software\Michael Herf\flux\Preferences"
        this.RegField := "Outdoor"
        this.DirectionFlipped := false
        this.ExePath := 'C:\Users\Eric\AppData\Local\FluxSoftware\Flux\flux.exe'
        this.Tolerance := 50     ; 判定"当前色温属于哪个预设"的容差
        this.TrayMenu := ""      ; 保存菜单对象引用，供 UpdateCheckmarks 使用
        this.Presets := [
            ["1050K: 炭火余温", 1050],
            ["1800K: 烛火微光", 1800],
            ["2300K: 暮色昏灯", 2300],
            ["2800K: 白炽暖光", 2800],
            ["3300K: 卤素柔辉", 3300],
            ["4300K: 荧光清和", 4300],
            ["5550K: 午日晴光", 5550],
            ["6550K: 白日天光", 6550]
        ]
    }

    Init() {
    }

    BuildMenu(trayMenu) {
        this.TrayMenu := trayMenu
        for preset in this.Presets
            trayMenu.Add(preset[1], ObjBindMethod(this, "SetPreset", preset[2]))
        trayMenu.Add()
        trayMenu.Add("f.lux 暂停/启用", ObjBindMethod(this, "TogglePause"))
        trayMenu.SetIcon("f.lux 暂停/启用", "shell32.dll", 322)

        ; 脚本启动 / 重建菜单时，如果 f.lux 已在运行，立即反映当前色温状态
        this.UpdateCheckmarks()
    }

    IsFluxRunning() {
        return ProcessExist("flux.exe") ? true : false
    }

    ; 确保 f.lux 正在运行；如果未运行，尝试启动并等待其就绪
    ; 返回 true 表示可以继续操作，false 表示启动失败
    EnsureFluxRunning() {
        if (this.IsFluxRunning())
            return true

        if (!FileExist(this.ExePath)) {
            TrayTip("f.lux 未安装或路径错误", "找不到: " this.ExePath, 3)
            return false
        }

        TrayTip("正在启动 f.lux...", "请稍候", 2)

        try
            Run('"' this.ExePath '"')
        catch as e {
            TrayTip("f.lux 启动失败", e.Message, 3)
            return false
        }

        ; 等待进程出现并准备就绪，最多等待约5秒
        maxWaitSteps := 25
        waitDelayMs := 200

        Loop maxWaitSteps {
            Sleep(waitDelayMs)
            if (this.IsFluxRunning())
                break
        }

        if (!this.IsFluxRunning()) {
            TrayTip("f.lux 启动超时", "请手动检查 f.lux 是否正常运行", 3)
            return false
        }

        ; 进程存在后，再稍等一下让其完成初始化（注册表/热键注册等）
        Sleep(800)
        return true
    }

    GetCurrentTemp() {
        try
            return RegRead(this.RegPath, this.RegField)
        catch
            return -1
    }

    ; 根据当前色温值，刷新所有预设菜单项的勾选状态
    ; 找到差值最小且在容差范围内的预设打勾，其余全部取消
    UpdateCheckmarks() {
        if (!this.TrayMenu)
            return

        currentTemp := this.GetCurrentTemp()
        if (currentTemp = -1) {
            for preset in this.Presets {
                try this.TrayMenu.Uncheck(preset[1])
            }
            return
        }

        closestLabel := ""
        closestDiff := 999999
        for preset in this.Presets {
            diff := Abs(preset[2] - currentTemp)
            if (diff < closestDiff) {
                closestDiff := diff
                closestLabel := preset[1]
            }
        }

        matched := (closestDiff <= this.Tolerance)
        for preset in this.Presets {
            try {
                if (matched && preset[1] = closestLabel)
                    this.TrayMenu.Check(preset[1])
                else
                    this.TrayMenu.Uncheck(preset[1])
            }
        }
    }

    SetPreset(targetTemp, *) {
        if (!this.EnsureFluxRunning())
            return

        maxSteps := 60
        tolerance := 50
        stepDelayMs := 150

        currentTemp := this.GetCurrentTemp()
        if (currentTemp = -1) {
            TrayTip("无法读取f.lux状态", "请确认f.lux正在运行", 2)
            return
        }

        Loop maxSteps {
            diff := targetTemp - currentTemp
            if (Abs(diff) <= tolerance)
                break

            wantWarmer := (diff < 0)
            useDown := wantWarmer
            if (this.DirectionFlipped)
                useDown := !useDown

            Send(useDown ? "!+{PgDn}" : "!+{PgUp}")
            Sleep(stepDelayMs)

            newTemp := this.GetCurrentTemp()
            if (newTemp = -1)
                break
            if (newTemp = currentTemp)
                break

            oldDiffAbs := Abs(diff)
            newDiffAbs := Abs(targetTemp - newTemp)

            if (newDiffAbs > oldDiffAbs) {
                this.DirectionFlipped := !this.DirectionFlipped
            } else if ((targetTemp - newTemp) * diff < 0) {
                currentTemp := newTemp
                break
            }

            currentTemp := newTemp
        }

        ; 调整结束后，根据实际达到的色温刷新菜单勾选状态
        this.UpdateCheckmarks()
    }

    TogglePause(*) {
        if (!this.EnsureFluxRunning())
            return
        Send("!{End}")
    }
}

ModuleRegistry.Register(FluxPresetModule())
