# 个人自动化脚本（AHK v2）

**主要功能：双击托盘图标切换系统深浅主题色、夜间自动降低音量、Copilot 键重映射为Ctrl、NumLock 状态反转、置顶切换、win+w 立即休眠**

基于 **AutoHotkey v2** 编写的个人自动化脚本集合，采用**模块化架构**。

每个功能独立成一个文件（一个 class），通过统一的注册表框架管理启动顺序、启用状态、托盘菜单生成。

---

## ✨ 特性

- 🧩 **模块化**：每个功能一个文件，互不干扰，方便单独维护
- 🗂️ **统一注册表**：自动处理初始化顺序、菜单排序、分组分隔线
- 🖱️ **托盘菜单自动生成**：无需手写菜单拼装逻辑
- 🔌 **易扩展**：新增功能只需新建一个文件 + 一行 `#Include`

---

## 📁 目录结构

```text
MyAutoScript/
├── main.ahk                     # 入口文件，仅含 #Include 清单 + 启动代码
├── core/
│   ├── ModuleBase.ahk            # 模块基类（固定不变，几乎不需要改）
│   └── ModuleRegistry.ahk        # 注册表：排序 / 初始化 / 建菜单（固定不变）
└── modules/
    ├── 10_NightVolume.ahk        # 夜间自动降低音量
    ├── 20_CopilotRemap.ahk       # Copilot 键重映射
    ├── 30_MouseAutoStart.ahk     # 鼠标控制程序自启动
    ├── 40_NumLockReverse.ahk     # NumLock 状态反转
    ├── 50_ThemeToggle.ahk        # 浅色 / 深色模式切换
    ├── 60_BacklightAutoOff.ahk   # 键盘背光自动关闭
    ├── 70_CloseScreen.ahk        # 立即关闭屏幕
    └── 90_WindowManager.ahk      # 置顶切换 + 移动窗口到下一显示器
    └── 100_HibernateHotkey.ahk   # Win+W 立即休眠

```


> **命名规则**：`modules/` 下文件名前缀数字（10 / 20 / 30 ...）**只是给人看的参考顺序**，不影响实际运行。

>
> 真正决定运行顺序的是模块内部的 `Priority` 属性。新增模块时，建议取一个比现有最大值大 10 的数字作前缀。

---

## 🚀 快速开始

1. 安装 [AutoHotkey v2](https://www.autohotkey.com/)

2. 克隆 / 下载本仓库

3. 双击运行 `main.ahk`

4. 右键任务栏托盘图标，即可看到所有功能菜单

常用快捷键：

| 快捷键 | 功能 |
|---|---|
| `Ctrl+Shift+Alt+R` | 重新加载脚本 |
| `Ctrl+Alt+Q` | 退出脚本 |
| `Ctrl+Alt+O` | 立即关闭屏幕 |

---

## 🧱 核心框架

框架由两个固定文件组成，**通常不需要修改**：

- `core/ModuleBase.ahk` —— 所有模块的基类，定义了 `Priority`、`MenuOrder`、`MenuGroup`、`Enabled` 等通用属性，以及默认的开关式菜单渲染逻辑

- `core/ModuleRegistry.ahk` —— 注册表，负责按 `Priority` 排序执行 `Init()`，按 `MenuOrder` 排序生成托盘菜单，并根据 `MenuGroup` 自动插入分隔线

新增功能时，只需要写一个新的模块文件，**不要**改动这两个核心文件（除非要扩展框架能力本身）。

---

## 📋 现有模块一览

| 文件 | 功能名称 | Priority | MenuOrder | MenuGroup | 说明 |
|---|---|---|---|---|---|
| `10_NightVolume.ahk` | 夜间自动降低音量 | 10 | 40 | 1 | 定时器检测 + 自动降低系统音量 |
| `20_CopilotRemap.ahk` | Copilot 键重映射 | 20 | 20 | 1 | 键盘热键重映射 |
| `30_MouseAutoStart.ahk` | 鼠标控制程序自启动 | 30 | — | — | 纯后台模块，不出现在菜单中 |
| `40_NumLockReverse.ahk` | NumLock 状态反转 | 40 | 30 | 1 | 数字键盘按键行为重映射 |
| `50_ThemeToggle.ahk` | 浅色 / 深色模式切换 | 50 | 70 | 4 | 自定义菜单（两个按钮：切浅色 / 切深色） |
| `60_BacklightAutoOff.ahk` | 键盘背光自动关闭 | 60 | 10 | 1 | 依赖 DllCall / 系统电源通知 |
| `70_CloseScreen.ahk` | 立即关闭屏幕 | 70 | 50 | 2 | 快捷键 `Ctrl+Alt+O`，单按钮无开关状态 |
| `90_WindowManager.ahk` | 置顶切换 + 移动窗口到下一显示器 | 90 | 25 | 1 | 纯热键驱动，不在菜单中出现开关 |


### 托盘菜单最终呈现顺序

```text
状态：正常运行中
──────────────
键盘背光自动关闭     (MenuGroup 1)
Copilot 键重映射     (MenuGroup 1)
NumLock 状态反转     (MenuGroup 1)
夜间自动降低音量     (MenuGroup 1)
──────────────
立即关闭屏幕         (MenuGroup 2)
──────────────
切换为浅色模式       (MenuGroup 4)
切换为深色模式
──────────────
重新加载脚本 / 打开脚本所在文件夹
──────────────
退出
```

**主题切换交互优化**：双击托盘图标可直接切换系统浅色/深色主题，无需展开右键菜单逐项选择
- **托盘菜单深色适配**：修复 Windows 11 最新 Insider 版本下右键菜单背景色不跟随系统深色/浅色主题的问题，菜单背景现已正确贴合当前系统主题
- 
---

## ➕ 如何新增一个功能模块

1. 在 `modules/` 下新建文件，命名格式为 `NN_功能名.ahk`（NN 取比现有最大值大 10 的数字）

2. 定义一个继承 `ModuleBase` 的类，类名格式为 `XxxModule`

3. 在 `__New()` 中至少设置以下属性：

   - `this.Name`（唯一标识，用于菜单显示和 `ModuleRegistry.Get()` 查找）

   - `this.Priority`（决定初始化顺序）

   - `this.MenuOrder` + `this.MenuGroup`（决定菜单显示位置和分组）

4. 如果是纯后台功能（不需要菜单开关），设置：

   ```autohotkey
   this.ShowInMenu := false
   this.ContributesToMenu := false
   ```

5. 如果需要自定义菜单展示（比如一组按钮），覆盖 `BuildMenu(trayMenu)` 方法，可参考 `80_FluxPreset.ahk` 的写法

6. 所有热键 / 定时器回调，必须用 `ObjBindMethod(this, "方法名")` 绑定，不能用裸函数名

7. 在 `main.ahk` 顶部手动添加一行：

   ```autohotkey
   #Include modules\你的文件名.ahk
   ```

8. 完成后，同步更新本 README「现有模块一览」表格

---

## ⚠️ AHK v2 语言层面的重要约束

1. **`#Include` 是编译期指令**，不支持通配符 / 变量 / 条件语句，不能用 `Loop Files` 动态包含文件，因此 `main.ahk` 顶部的 Include 清单必须手动维护

2. **自动执行段截断问题**：脚本顶层遇到静态热键标签（如 `key::`）、`Return`、`Exit` 会截断自动执行段的执行

   本项目通过「模块文件只声明 class，最后一行调用 `ModuleRegistry.Register(...)`」的方式规避此问题，新模块必须遵循同样的模式，**不要**在模块文件顶层写裸的热键定义或直接执行的语句

3. `OnMessage()` 和 `OnExit()` 在 v2 中支持多次调用叠加注册回调，不同模块可以各自独立注册，互不覆盖

4. class 方法作为回调（热键 / 定时器 / 菜单项）时，必须用：

   ```autohotkey
   ObjBindMethod(this, "MethodName")
   ```

   或箭头函数：

   ```autohotkey
   (*) => this.Method()
   ```

   直接传方法名字符串无法访问 `this` 上下文

---

## 🔧 修改已有模块

- 只需要提供**该模块对应的单个文件**即可，不需要整个项目

- 涉及「启动顺序」→ 改 `Priority`

- 涉及「菜单排列顺序 / 分组」→ 改 `MenuOrder` / `MenuGroup`

- **两者不要混用**，这是本项目最容易踩坑的地方

- 模块间通信请用 `ModuleRegistry.Get("模块名")` 获取实例后调用方法，**不要使用全局变量**

---

## 📄 License

个人项目，仅供自用与学习参考。
