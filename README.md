# AutoHotkey v2 夜间自动化与按键重映射工具

这是一个基于 AutoHotkey v2 开发的轻量级后台自动化脚本。

主要用于夜间自动降低系统音量、按键重映射、常用系统操作快捷键，以及将笔记本 NumLock 数字键区的灯亮/灯灭状态与实际输出功能进行互换。

## ✨ 核心功能

- 🔉 **夜间自动降音量**：在设定的夜间时间段内，定时自动下调一档系统音量，避免夜间突发高音量打扰。

- ⌨️ **Copilot 键重映射**：将 Windows 新版键盘上的 Copilot 键（映射为 F23）改键为**右 Ctrl**（RControl），恢复经典键盘操作习惯。

- 🖱️ **自启动鼠标控制程序**：脚本运行时自动启动 X-Mouse Button Control。

- 🔢 **NumLock 灯状态互换**：灯灭 = 数字模式，灯亮 = 方向/编辑模式（方向键、Home/End/PgUp/PgDn/Insert/Delete），彻底解决部分笔记本无法关闭 NumLock 指示灯的困扰。

- ⚡ **常用快捷键支持**：随时手动关屏、一键重载/退出脚本。

- 📌 **托盘快捷菜单**：系统托盘图标右键菜单，支持状态查询与手动操作。

> ⚠️ 说明：早期版本包含"夜间闲置自动关屏"功能，实测体验不佳（存在误触发/唤醒不稳定等问题），已在当前版本中移除，仅保留手动关屏快捷键。

## 🛠️ 环境要求

- 操作系统：Windows 10 / Windows 11

- 运行环境：AutoHotkey v2.0 及以上版本

## ⚙️ 可调参数配置

打开 `.ahk` 文件顶部，可直接修改以下区块参数以适应个人习惯：

```ahk
; --- 夜间时间段定义（24小时制 HHmm 格式）---
NightStartTime := "2030"   ; 夜间开始时间（默认 20:30）
NightEndTime   := "0900"   ; 夜间结束时间（默认 次日 09:00）

; --- 夜间降音量参数 ---
VolumeCheckIntervalMs := 1200000  ; 降音量检测间隔（毫秒，默认 20分钟）

⌨️ 快捷键列表
快捷键	功能说明	限制条件
Ctrl + Alt + O	立即关闭屏幕	全天随时可用
Ctrl + Shift + Alt + R	重新加载脚本	—
Ctrl + Alt + Q	退出脚本	—
Copilot 键（F23）	映射为右 Ctrl	—
🔢 NumLock 键位对照表
物理键（灯亮时信号）	实际输出（灯亮=方向模式）
Numpad0	Insert
Numpad1	End
Numpad2	↓ 方向键
Numpad3	Page Down
Numpad4	← 方向键
Numpad5	Clear
Numpad6	→ 方向键
Numpad7	Home
Numpad8	↑ 方向键
Numpad9	Page Up
NumpadDot	Delete
灯灭时同一物理键区自动切换为对应数字 0-9 和小数点，加减乘除及 Enter 键两种状态下功能保持一致，不受影响。

脚本默认开机时强制将 NumLock 状态设为 Off（灯灭 + 数字模式）。

如需彻底禁用物理 NumLock 键的切换能力，可将脚本中的 SetNumLockState("Off") 改为 SetNumLockState("AlwaysOff")。

🖱️ 托盘菜单指南
右键点击任务栏右下角的脚本图标，可使用以下功能：

立即关闭屏幕：手动关屏，无需等待闲置超时。

查看当前是否为夜间模式：弹窗显示当前时间以及夜间逻辑的激活状态。

重新加载脚本 / 退出脚本：快捷管理后台进程。

🚀 使用方法
安装 AutoHotkey v2。

将代码保存为 NightHelper.ahk（或任意名称）。

双击运行 .ahk 文件即可生效。

（可选）将脚本或其快捷方式放入 Windows 开机启动文件夹（Shell:startup）以实现开机自启。

⚠️ 注意事项
脚本中 X-Mouse Button Control 的启动路径为硬编码路径，如未安装该程序或安装路径不同，请自行修改或删除该行代码，否则可能报错。

Copilot 键重映射依赖于系统将该键识别为 F23，不同品牌/型号笔记本的实际映射键值可能不同，如不生效可用 AutoHotkey 自带的 Window Spy 工具查看实际按键名称。


