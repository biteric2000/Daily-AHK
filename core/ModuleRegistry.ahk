; ════════════════════════════════════════════════════════════════
; 文件: core/ModuleRegistry.ahk
; ════════════════════════════════════════════════════════════════

class ModuleRegistry {
    static Modules := []

    static Register(moduleInstance) {
        ModuleRegistry.Modules.Push(moduleInstance)
    }

    ; 通用冒泡排序，按任意字段排序
    static _SortBy(fieldName) {
        arr := ModuleRegistry.Modules.Clone()
        n := arr.Length
        Loop n - 1 {
            i := A_Index
            Loop n - i {
                j := A_Index
                if (arr[j].%fieldName% > arr[j + 1].%fieldName%) {
                    tmp := arr[j]
                    arr[j] := arr[j + 1]
                    arr[j + 1] := tmp
                }
            }
        }
        return arr
    }

    static SortByPriority() {
        return ModuleRegistry._SortBy("Priority")
    }

    static SortByMenuOrder() {
        return ModuleRegistry._SortBy("MenuOrder")
    }

    static InitAll() {
        for mod in ModuleRegistry.SortByPriority() {
            if (mod.Enabled) {
                try {
                    mod.Init()
                } catch as e {
                    TrayTip("模块初始化失败: " mod.Name, e.Message, 3)
                }
            }
        }
    }

    static Get(name) {
        for mod in ModuleRegistry.Modules {
            if (mod.Name = name)
                return mod
        }
        return ""
    }

    static BuildTrayMenu() {
        A_TrayMenu.Delete()
        A_TrayMenu.Add("状态：正常运行中", (*) => "")
        A_TrayMenu.Disable("状态：正常运行中")
        A_TrayMenu.Add()

        lastGroup := ""
        for mod in ModuleRegistry.SortByMenuOrder() {
            if (!mod.ContributesToMenu)
                continue
            if (lastGroup != "" && mod.MenuGroup != lastGroup)
                A_TrayMenu.Add()
            mod.BuildMenu(A_TrayMenu)
            lastGroup := mod.MenuGroup
        }

        A_TrayMenu.Add()
        A_TrayMenu.Add("重新加载脚本", (*) => Reload())
        A_TrayMenu.Add("打开脚本所在文件夹", (*) => Run("explorer.exe " A_ScriptDir))
        A_TrayMenu.Add()
        A_TrayMenu.Add("退出", (*) => ExitApp())
        A_TrayMenu.Default := "重新加载脚本"
    }
}