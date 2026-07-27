; ════════════════════════════════════════════════════════════════
; 文件: modules/10_NightVolume.ahk
; ════════════════════════════════════════════════════════════════

class NightVolumeModule extends ModuleBase {
    __New() {
        this.Name := "夜间自动降低音量"
        this.Priority := 10       ; 启动顺序：优先注册定时器
        this.MenuOrder := 40      ; 菜单顺序：还原到原来第4位
        this.MenuGroup := 1
        this.MenuIcon := ["shell32.dll", 175]
        this.NightStartTime := "2030"
        this.NightEndTime := "0900"
        this.MinVolumePercent := 3
        this.CheckIntervalMs := 1200000
    }

    Init() {
        SetTimer(ObjBindMethod(this, "CheckAndReduce"), this.CheckIntervalMs)
    }

    IsNightTime() {
        t := FormatTime(, "HHmm")
        return (t >= this.NightStartTime or t < this.NightEndTime)
    }

    CheckAndReduce() {
        if (!this.Enabled || !this.IsNightTime())
            return
        if (SoundGetVolume() > this.MinVolumePercent)
            Send("{Volume_Down}")
    }
}

ModuleRegistry.Register(NightVolumeModule())
