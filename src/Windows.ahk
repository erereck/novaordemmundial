HideTaskbar() {
    try {
        WinHide("ahk_class Shell_TrayWnd")
    } catch {
    }

    try {
        for hwnd in WinGetList("ahk_class Shell_SecondaryTrayWnd")
            WinHide("ahk_id " hwnd)
    } catch {
    }
}

ShowTaskbar() {
    try {
        WinShow("ahk_class Shell_TrayWnd")
    } catch {
    }

    try {
        for hwnd in WinGetList("ahk_class Shell_SecondaryTrayWnd")
            WinShow("ahk_id " hwnd)
    } catch {
    }
}

RestoreWindows(*) {
    ShowTaskbar()
}

LauncherActive() {
    global UI, UI_VISIBLE

    if !UI_VISIBLE
        return false

    if !IsObject(UI)
        return false

    try {
        return WinActive("ahk_id " UI.Hwnd) != 0
    } catch {
        return false
    }
}
