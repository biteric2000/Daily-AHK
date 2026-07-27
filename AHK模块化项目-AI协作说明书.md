# AHK v2 个人自动化脚本 —— 项目上下文说明书

> 本文档用于告知 AI 本项目的完整架构约定。以后新增/修改功能时，
> 只需把本文档 + 需要改动的模块文件发给 AI，无需上传整个项目。

---

## 一、项目概述

这是一个基于 **AutoHotkey v2** 的个人自动化脚本项目，采用**模块化架构**，
每个功能独立成一个文件（一个 class），通过统一的注册表框架管理
启动顺序、启用状态、托盘菜单生成。

**技术栈约束（必须遵守）：**
- AutoHotkey v2.0 语法（不是 v1，语法差异很大，写代码前务必确认用 v2 写法）
- `#Requires AutoHotkey v2.0`

---

## 二、目录结构

```
MyAutoScript/
├── main.ahk                     # 入口文件，仅含 #Include 清单 + 启动代码
├── core/
│   ├── ModuleBase.ahk            # 模块基类（固定不变，几乎不需要改）
│   └── ModuleRegistry.ahk        # 注册表：排序/初始化/建菜单（固定不变）
└── modules/
    ├── 10_NightVolume.ahk        # 夜间自动降低音量
    ├── 20_CopilotRemap.ahk       # Copilot键重映射
    ├── 30_MouseAutoStart.ahk     # 鼠标控制程序自启动
    ├── 40_NumLockReverse.ahk     # NumLock状态反转
    ├── 50_ThemeToggle.ahk        # 浅色/深色模式切换
    ├── 60_BacklightAutoOff.ahk   # 键盘背光自动关闭
    ├── 70_CloseScreen.ahk        # 立即关闭屏幕
    └── 80_FluxPreset.ahk         # f.lux 色温预设
```

**命名规则**：`modules/` 下文件名前缀数字（10/20/30...）**只是给人看的参考顺序，
不影响实际运行**。真正决定顺序的是模块内部的 `Priority` 属性。新增模块时，
建议取一个比现有最大值大 10 的数字作前缀（比如现有到 90）。

---

## 三、核心框架代码（固定不变，通常不需要修改）

以下两个文件是整套框架的骨架。**除非用户明确要求扩展框架能力，
否则不要修改这两个文件**，新增功能只需要写新的模块文件。

### 3.1 core/ModuleBase.ahk

```autohotkey
class ModuleBase {
    Name := "未命名模块"
    Priority := 100           ; 启动顺序：数字越小越先执行 Init()
    MenuOrder := 100           ; 菜单显示顺序：数字越小越靠前（与Priority完全独立）
    MenuGroup := 0             ; 分组号：相邻模块 MenuGroup 不同则自动插入分隔线
    Enabled := true
    MenuIcon := ""             ; 形如 ["shell32.dll", 152]，留空则不设图标
    ShowInMenu := true         ; true=用默认"开关式"菜单项渲染
    ContributesToMenu := true  ; false=完全不参与菜单排序/分组（纯后台模块用）

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
```

### 3.2 core/ModuleRegistry.ahk

```autohotkey
class ModuleRegistry {
    static Modules := []

    static Register(moduleInstance) {
        ModuleRegistry.Modules.Push(moduleInstance)
    }

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
```

### 3.3 main.ahk（入口文件全貌）

```autohotkey
#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent
SetKeyDelay(50, 50)

#Include core\ModuleBase.ahk
#Include core\ModuleRegistry.ahk

#Include modules\10_NightVolume.ahk
#Include modules\20_CopilotRemap.ahk
#Include modules\30_MouseAutoStart.ahk
#Include modules\40_NumLockReverse.ahk
#Include modules\50_ThemeToggle.ahk
#Include modules\60_BacklightAutoOff.ahk
#Include modules\70_CloseScreen.ahk
#Include modules\80_FluxPreset.ahk
#Include modules\90_WindowManager.ahk
; 新增模块时，在这里加一行 #Include，就像其他语言写 import

^+!r:: Reload()
^!q:: ExitApp()

TraySetIcon("shell32.dll", 145)
A_IconTip := "个人自动化脚本`n右键查看所有功能"

ModuleRegistry.InitAll()
ModuleRegistry.BuildTrayMenu()
```

---

## 四、现有模块清单（关键属性一览表）

> 这张表让 AI 即使没看到某个模块的源码，也知道它在系统里的"坐标"，
> 方便判断新模块的 Priority/MenuOrder/MenuGroup 该取什么值不会冲突。

| 文件 | Name | Priority | MenuOrder | MenuGroup | ShowInMenu | 说明 |
|---|---|---|---|---|---|---|
| 10_NightVolume.ahk | 夜间自动降低音量 | 10 | 40 | 1 | true | 定时器检测+降音量 |
| 20_CopilotRemap.ahk | Copilot键重映射 | 20 | 20 | 1 | true | 热键重映射 |
| 30_MouseAutoStart.ahk | 鼠标控制程序自启动 | 30 | - | - | false（ContributesToMenu=false） | 纯后台，不进菜单 |
| 40_NumLockReverse.ahk | NumLock状态反转 | 40 | 30 | 1 | true | 数字键盘重映射 |
| 50_ThemeToggle.ahk | 主题切换 | 50 | 70 | 4 | 自定义BuildMenu（2个按钮） | 深浅色切换 |
| 60_BacklightAutoOff.ahk | 键盘背光自动关闭 | 60 | 10 | 1 | true | 依赖DllCall/电源通知 |
| 70_CloseScreen.ahk | 立即关闭屏幕 | 70 | 50 | 2 | 自定义BuildMenu（单按钮，无开关状态） | 快捷键Ctrl+Alt+O |
| 80_FluxPreset.ahk | f.lux 色温预设 | 80 | 60 | 3 | 自定义BuildMenu（多个预设按钮） | 依赖flux.exe进程+注册表读值 |
| 90_WindowManager.ahk | 置顶切换 + 移动窗口到下一显示器 | 90 | 25 | 1 | false | 纯热键驱动，无需菜单开关 |

**托盘菜单最终呈现顺序**（按 MenuOrder 排列，同 MenuGroup 相邻不分隔线）：
```
状态：正常运行中
──────────────
键盘背光自动关闭 (MenuGroup 1)
Copilot键重映射   (MenuGroup 1)
NumLock状态反转   (MenuGroup 1)
夜间自动降低音量  (MenuGroup 1)
──────────────
立即关闭屏幕      (MenuGroup 2)
──────────────
[f.lux 8个预设按钮] (MenuGroup 3)
f.lux 暂停/启用
──────────────
切换为浅色模式    (MenuGroup 4)
切换为深色模式
──────────────
重新加载脚本 / 打开脚本所在文件夹
──────────────
退出
```

---

## 五、新增/修改模块的规则（AI 必须遵守）

### 5.1 新增一个功能模块时

1. **不要**把新逻辑塞进已有模块文件，**必须**新建一个独立文件，
   类名为 `XxxModule`，继承 `ModuleBase`。
2. `__New()` 里必须设置：`this.Name`（唯一，用于菜单和 `ModuleRegistry.Get()` 查找）、
   `this.Priority`（参考上表选一个不冲突的值，决定初始化顺序）、
   `this.MenuOrder` + `this.MenuGroup`（决定菜单里排在哪个位置/哪个分组）。
3. 如果是纯后台功能（不需要在菜单里出现开关），设置
   `this.ShowInMenu := false` 且 `this.ContributesToMenu := false`。
4. 如果需要自定义菜单展示（不是简单的开关，比如一组按钮），
   覆盖 `BuildMenu(trayMenu)` 方法，参考 `80_FluxPreset.ahk` 或 `50_ThemeToggle.ahk` 的写法。
5. 所有需要在 `Init()` 里注册的热键/定时器，**必须**用
   `ObjBindMethod(this, "方法名")` 绑定，不能用裸函数名（AHK v2 class 方法必须这样绑定才能拿到 `this`）。
6. 写完后提醒用户：**需要在 `main.ahk` 顶部手动加一行 `#Include modules\你的文件名.ahk`**
   （这是 AHK 语言本身的限制，`#Include` 是编译期指令，无法自动扫描目录，必须手动列出，
   这一步类似其他语言写 `import`）。
7. 把新模块的关键属性（Name/Priority/MenuOrder/MenuGroup）补充到本文档第四节的表格里，
   方便下次维护时上下文完整。

### 5.2 修改已有模块时

- 只需要用户提供**该模块对应的单个文件**即可，不需要整个项目。
- 如果改动涉及"启动顺序"，改 `Priority`；如果涉及"菜单排列顺序/分组"，改
  `MenuOrder`/`MenuGroup`；**两者不要混用**，这是本项目最容易踩坑的地方
  （历史上发生过把两者揉在一起导致菜单顺序跟预期不一致的问题）。
- 如果模块需要引用其他模块的功能（比如"切换深色模式时顺便关闭屏幕"），
  用 `ModuleRegistry.Get("立即关闭屏幕")` 拿到实例后调用其方法，
  **不要用全局变量**做模块间通信。

### 5.3 AI 回复格式要求

- 只输出**改动涉及的文件**的完整内容，不要重新输出整个项目其他没变动的模块。
- 如果改动导致上面第四节表格的属性值变化，在回复末尾提醒需要同步更新表格。
- 如果新增模块，在回复末尾明确写出："请在 main.ahk 中添加：`#Include modules\xxx.ahk`"。

---

## 六、AHK v2 语言层面的重要约束（AI 写代码时务必注意）

1. `#Include` 是**编译期指令**，不支持通配符/变量/条件语句，
   不能用 `Loop Files` 之类动态包含文件——这是本项目"手动维护 main.ahk 顶部
   Include 清单"这一设计的根本原因，无法绕过。
2. AHK v2 存在"自动执行段"概念：脚本顶层遇到静态热键标签（如 `key::`）、
   `Return`、`Exit` 会截断自动执行段的执行。本项目通过"所有模块只声明 class，
   不在顶层跑逻辑，最后一行调用 `ModuleRegistry.Register(...)`"的方式规避了这个坑
   （纯赋值/函数调用不会截断自动执行段，是安全的）。**新模块必须遵循这个模式**，
   不要在模块文件顶层写裸的热键定义或直接执行的语句。
3. `OnMessage()` 和 `OnExit()` 在 v2 中允许多次调用叠加注册回调（不会互相覆盖），
   所以不同模块都可以独立调用它们注册自己的回调，互不影响。
4. class 方法作为回调（热键、定时器、菜单项）时必须用 `ObjBindMethod(this, "MethodName")`
   或 `(*) => this.Method()` 的箭头函数形式绑定，直接传方法名字符串是无法访问 `this` 上下文的。

---

## 七、给用户的使用说明（非AI阅读部分，人类参考）

以后有新需求，按以下步骤操作：

1. 把**本文档**发给 AI。
2. 如果是修改已有功能：只需额外发送**对应的那一个模块文件**（比如只改
   f.lux 相关逻辑，就只发 `80_FluxPreset.ahk`）。
3. 如果是新增功能：不需要发任何现有模块文件，直接描述需求即可，
   AI 会按第五节规则生成新文件，并提示你需要在 `main.ahk` 加哪一行 `#Include`。
4. 如果涉及框架能力扩展（比如想要模块间依赖检查、配置文件外置等），
   额外发送 `core/ModuleBase.ahk` 和 `core/ModuleRegistry.ahk`
   （虽然本文档已包含这两个文件内容，但如果你本地有手动改动过，
   记得同步告知 AI 最新版本，避免 AI 基于过时版本生成代码）。
5. 每次新增/修改完成后，记得手动同步更新本文档第四节的模块清单表格，
   保证下次沟通时上下文依然准确。