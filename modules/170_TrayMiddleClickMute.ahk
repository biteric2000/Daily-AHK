#Requires AutoHotkey v2.0

; ========================================================
; 模块：中键点击托盘图标 → 切换系统静音
; 原理：监听 Shell 转发的托盘图标消息 (0x404)，
; 判断 lParam = WM_MBUTTONUP(0x208) 时触发，
; 调用 AHK v2 内置 SoundSetMute(-1) 实现"切换"语义
; 纯交互式便捷功能，不需要开关状态，不在托盘菜单中出现
; ========================================================
class TrayMiddleClickMuteModule extends ModuleBase {

    static WM_TRAYNOTIFY := 0x404
    static WM_MBUTTONUP := 0x208

    __New() {
        this.Name := "中键静音切换"
        this.Priority := 170
        this.ShowInMenu := false
        this.ContributesToMenu := false   ; 纯后台交互，不占用菜单位置
    }

    Init() {
        ; 注册托盘图标消息监听，多模块可叠加注册，互不覆盖
        OnMessage(TrayMiddleClickMuteModule.WM_TRAYNOTIFY, ObjBindMethod(this, "OnTrayMessage"))
    }

    ; OnMessage 回调固定签名：(wParam, lParam, msg, hwnd)
    OnTrayMessage(wParam, lParam, msg, hwnd) {
        ; 只响应"中键释放"，忽略左键/右键/双击等其他动作，避免抢夺原有菜单功能
        if (lParam != TrayMiddleClickMuteModule.WM_MBUTTONUP)
            return

        SoundSetMute(-1)   ; -1 = 切换当前静音状态

        ; 切换后查询实际状态，给用户一个短暂的可视反馈
        isMuted := SoundGetMute()
        ; TrayTip(isMuted ? "🔇 已静音" : "🔊 已取消静音", , 1)
    }
}

ModuleRegistry.Register(TrayMiddleClickMuteModule())