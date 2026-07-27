; ════════════════════════════════════════════════════════════════
; 文件: core/ModuleBase.ahk
; ════════════════════════════════════════════════════════════════

class ModuleBase {
    Name := "未命名模块"
    Priority := 100          ; 启动顺序：数字越小越先 Init()
    MenuOrder := 100          ; 菜单顺序：数字越小越靠前显示（与 Priority 完全独立）
    MenuGroup := 0            ; 分组号：相邻模块 MenuGroup 不同时自动插入分隔线
    Enabled := true
    MenuIcon := ""
    ShowInMenu := true        ; 是否用【默认的开关式菜单】渲染
    ContributesToMenu := true ; 是否参与菜单排序/分组（纯后台模块设为 false）

    Init() {
    }

    BuildMenu(trayMenu) {
        if (!this.ShowInMenu)
            return
        trayMenu.Add(this.Name, ObjBindMethod(this, "Toggle"))
        if (this.Enabled)
            trayMenu.Check(this.Name)
        if (this.MenuIcon)
            trayMenu.SetIcon(this.Name, this.MenuIcon[1], this.MenuIcon[2])
    }

    Toggle(*) {
        this.Enabled := !this.Enabled
        try A_TrayMenu.ToggleCheck(this.Name)
        this.OnToggle()
    }

    OnToggle() {
    }
}
