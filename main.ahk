
; ════════════════════════════════════════════════════════════════
; 文件: main.ahk
; ════════════════════════════════════════════════════════════════

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
;#Include modules\70_CloseScreen.ahk
;#Include modules\80_FluxPreset.ahk
;#Include modules\90_WindowManager.ahk
;#Include lib/TrayIconRenderer.ahk
#Include modules\100_HibernateHotkey.ahk
;#Include modules\110_MouseComboTaskView.ahk
#Include modules\130_XButtonComboAltSpace.ahk
#Include modules\140_GameModeIMEBlock.ahk
#Include modules\150_PureTextPaste.ahk
#Include modules\160_AeroShakeToggle.ahk
#Include modules\170_TrayMiddleClickMute.ahk


^+!r:: Reload()
^!q:: ExitApp()

TraySetIcon("shell32.dll", 145)
A_IconTip := "Eric's Tool`n左键双击切换系统颜色`n右键查看所有功能"

ModuleRegistry.InitAll()
ModuleRegistry.BuildTrayMenu()
