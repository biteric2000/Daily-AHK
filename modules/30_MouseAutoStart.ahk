; ════════════════════════════════════════════════════════════════
; 文件: modules/30_MouseAutoStart.ahk
; ════════════════════════════════════════════════════════════════

class MouseAutoStartModule extends ModuleBase {
      __New() {
          this.Name := "鼠标控制程序自启动"
          this.Priority := 30
          this.ShowInMenu := false
          this.ContributesToMenu := false  ; 完全不参与菜单排序/分组
          this.ExePath := 'C:\Program Files\Highresolution Enterprises\X-Mouse Button Control\XMouseButtonControl.exe'
          this.ExeName := 'XMouseButtonControl.exe'
      }

      Init() {
          ; 如果进程已在运行，直接返回，什么也不做
          if (ProcessExist(this.ExeName))
              return

          if (FileExist(this.ExePath))
              Run('"' this.ExePath '"')
      }
}

ModuleRegistry.Register(MouseAutoStartModule())