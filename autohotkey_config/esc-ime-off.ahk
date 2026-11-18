#Requires AutoHotkey v2.0
#SingleInstance Force
DetectHiddenWindows true  ; IME 制御用ウィンドウは非表示のため必要
; Windows Terminal で Esc を押したら IME をオフにする（Esc 自体はそのまま渡す）。
; Claude Code の vim モードで、NORMAL に戻ったときに日本語入力のままになるのを防ぐ。

SetIME(open) {
    hwnd := WinExist("A")
    ime := DllCall("imm32\ImmGetDefaultIMEWnd", "Ptr", hwnd, "Ptr")
    if !ime
        return
    ; WM_IME_CONTROL(0x283), IMC_SETOPENSTATUS(0x6)
    SendMessage(0x283, 0x6, open ? 1 : 0, , "ahk_id " ime)
}

#HotIf WinActive("ahk_exe WindowsTerminal.exe")
~Esc:: SetIME(false)
#HotIf
