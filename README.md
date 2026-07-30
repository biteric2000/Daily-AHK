# 个人自动化脚本（AHK v2）

主要功能：双击托盘图标切换系统深浅主题色、夜间自动降低音量、Copilot 键重映射为Ctrl、
NumLock 状态反转、置顶切换、Win+W 立即休眠、Win+V 纯文本粘贴、Aero Shake 开关、
中键点击托盘图标静音切换

基于 AutoHotkey v2 编写的个人自动化脚本集合，采用模块化架构。

每个功能独立成一个文件（一个 class），通过统一的注册表框架管理启动顺序、启用状态、托盘菜单生成。

## ✨ 特性

- 🧩 **模块化**：每个功能一个文件，互不干扰，方便单独维护
- 🗂️ **统一注册表**：自动处理初始化顺序、菜单排序、分组分隔线
- 🖱️ **托盘菜单自动生成**：无需手写菜单拼装逻辑
- 🔌 **易扩展**：新增功能只需新建一个文件 + 一行 `#Include`
- 📋 **剪贴板/系统级功能覆盖广**：纯文本粘贴、静音切换、Aero Shake 均无需第三方软件

## 📁 目录结构

```
MyAutoScript/
├── main.ahk                       # 入口文件，仅含 #Include 清单 + 启动代码
├── core/
│   ├── ModuleBase.ahk              # 模块基类（固定不变，几乎不需要改）
│   └── ModuleRegistry.ahk          # 注册表：排序 / 初始化 / 建菜单（固定不变）
└── modules/
    ├── 10_NightVolume.ahk          # 夜间自动降低音量
    ├── 20_CopilotRemap.ahk         # Copilot 键重映射
    ├── 30_MouseAutoStart.ahk       # 鼠标控制程序自启动
    ├── 40_NumLockReverse.ahk       # NumLock 状态反转
    ├── 50_ThemeToggle.ahk          # 浅色 / 深色模式切换
    ├── 60_BacklightAutoOff.ahk     # 键盘背光自动关闭
    ├── 70_CloseScreen.ahk          # 立即关闭屏幕
    ├── 90_WindowManager.ahk        # 置顶切换 + 移动窗口到下一显示器
    ├── 100_HibernateHotkey.ahk     # Win+W 立即休眠
    ├── 110_MouseComboTaskView.ahk  # 右键+中键同按 → 任务视图
    ├── 130_XButtonComboAltSpace.ahk # 鼠标4键+5键同按 → Alt+Space系统菜单
    ├── 140_GameModeIMEBlock.ahk    # 游戏模式：屏蔽输入法切换（默认关闭）
    ├── 150_PureTextPaste.ahk       # Win+V 纯文本粘贴（去格式）
    ├── 160_AeroShakeToggle.ahk     # Aero Shake（抖动最小化窗口）开关
    └── 170_TrayMiddleClickMute.ahk # 中键点击托盘图标 → 切换系统静音
```

命名规则：`modules/` 下文件名前缀数字（10 / 20 / 30 ...）只是给人看的参考顺序，不影响实际运行。

真正决定运行顺序的是模块内部的 `Priority` 属性。新增模块时，建议取一个比现有最大值大 10 的数字作前缀。

## 🚀 快速开始

1. 安装 AutoHotkey v2
2. 克隆 / 下载本仓库
3. 双击运行 `main.ahk`
4. 右键任务栏托盘图标，即可看到所有功能菜单

常用快捷键 / 鼠标操作：

| 操作 | 功能 |
|---|---|
| `Ctrl+Shift+Alt+R` | 重新加载脚本 |
| `Ctrl+Alt+Q` | 退出脚本 |
| `Ctrl+Alt+O` | 立即关闭屏幕 |
| `Win+W` | 立即休眠 |
| `Win+V` | 纯文本粘贴（去除RTF/HTML等格式，粘贴后自动恢复原剪贴板内容） |
| 双击托盘图标 | 直接切换浅色/深色主题 |
| 中键点击托盘图标 | 切换系统静音 / 取消静音 |

## 🧱 核心框架

框架由两个固定文件组成，通常不需要修改：

- `core/ModuleBase.ahk` —— 所有模块的基类，定义了 `Priority`、`MenuOrder`、`MenuGroup`、`Enabled` 等通用属性，以及默认的开关式菜单渲染逻辑
- `core/ModuleRegistry.ahk` —— 注册表，负责按 `Priority` 排序执行 `Init()`，按 `MenuOrder` 排序生成托盘菜单，并根据 `MenuGroup` 自动插入分隔线

新增功能时，只需要写一个新的模块文件，不要改动这两个核心文件（除非要扩展框架能力本身）。

## 📋 现有模块一览

| 文件 | 功能名称 | Priority | MenuOrder | MenuGroup | 说明 |
|---|---|---|---|---|---|
| `10_NightVolume.ahk` | 夜间自动降低音量 | 10 | 40 | 1 | 定时器检测 + 自动降低系统音量 |
| `20_CopilotRemap.ahk` | Copilot 键重映射 | 20 | 20 | 1 | 键盘热键重映射 |
| `30_MouseAutoStart.ahk` | 鼠标控制程序自启动 | 30 | — | — | 纯后台模块，不出现在菜单中 |
| `40_NumLockReverse.ahk` | NumLock 状态反转 | 40 | 30 | 1 | 数字键盘按键行为重映射 |
| `50_ThemeToggle.ahk` | 浅色 / 深色模式切换 | 50 | 70 | 4 | 自定义菜单（两个按钮），支持双击托盘图标直接切换 |
| `60_BacklightAutoOff.ahk` | 键盘背光自动关闭 | 60 | 10 | 1 | 依赖 DllCall / 系统电源通知 |
| `70_CloseScreen.ahk` | 立即关闭屏幕 | 70 | 50 | 2 | 快捷键 Ctrl+Alt+O，单按钮无开关状态 |
| `90_WindowManager.ahk` | 置顶切换 + 移动窗口到下一显示器 | 90 | 25 | 1 | 纯热键驱动，不在菜单中出现开关 |
| `100_HibernateHotkey.ahk` | 立即休眠 | 100 | — | — | 快捷键 Win+W，纯后台模块，不出现在菜单中 |
| `110_MouseComboTaskView.ahk` | 右键+中键→任务视图 | ？ | ？ | ？ | 属性待补充，欢迎补充文件后完善本表 |
| `130_XButtonComboAltSpace.ahk` | 鼠标4/5键→系统菜单 | ？ | ？ | ？ | 属性待补充，欢迎补充文件后完善本表 |
| `140_GameModeIMEBlock.ahk` | 游戏模式屏蔽输入法切换 | ？ | ？ | ？ | 默认关闭，属性待补充 |
| `150_PureTextPaste.ahk` | Win+V 纯文本粘贴 | 150 | 45 | 1 | 剪贴板换入换出法，粘贴后自动恢复原剪贴板 |
| `160_AeroShakeToggle.ahk` | Aero Shake 开关 | 160 | 46 | 1 | 控制"抖动标题栏最小化其它窗口"功能，默认开启 |
| `170_TrayMiddleClickMute.ahk` | 中键静音切换 | 170 | — | — | 中键点击托盘图标切换系统静音，纯交互无菜单项 |

### 托盘菜单最终呈现顺序

```
状态：正常运行中
──────────────
键盘背光自动关闭      (MenuGroup 1)
Copilot 键重映射      (MenuGroup 1)
NumLock 状态反转      (MenuGroup 1)
夜间自动降低音量      (MenuGroup 1)
纯文本粘贴(Win+V)     (MenuGroup 1)
Aero Shake(抖动最小化) (MenuGroup 1)
──────────────
立即关闭屏幕          (MenuGroup 2)
──────────────
切换为浅色模式        (MenuGroup 4)
切换为深色模式
──────────────
重新加载脚本 / 打开脚本所在文件夹
──────────────
退出
```

- 主题切换交互优化：双击托盘图标可直接切换系统浅色/深色主题，无需展开右键菜单逐项选择
- 中键点击托盘图标：直接切换系统静音/取消静音，无需打开音量控制面板
- 托盘菜单深色适配：修复 Windows 11 最新 Insider 版本下右键菜单背景色不跟随系统深色/浅色主题的问题，菜单背景现已正确贴合当前系统主题

## ➕ 如何新增一个功能模块

1. 在 `modules/` 下新建文件，命名格式为 `NN_功能名.ahk`（NN 取比
