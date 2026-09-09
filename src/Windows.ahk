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
    ; Antes de sair, nenhuma janela deve continuar presa como topmost por nossa causa.
    ReleaseStudentTopmost()
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

ReleaseStudentTopmost() {
    global STUDENT_WINDOWS

    for hwnd, _ in STUDENT_WINDOWS {
        if WinExist("ahk_id " hwnd) {
            try WinSetAlwaysOnTop(0, "ahk_id " hwnd)
        }
    }
}

CloseAllOutsideLauncher(*) {
    global UI, UI_VISIBLE
    global STUDENT_WINDOWS, STUDENT_PIDS, LAST_STUDENT_HWND
    global EXTERNAL_ACTIVE, EXTERNAL_PID, EXTERNAL_HWND, EXTERNAL_TITLE

    launcherHwnd := 0
    if IsObject(UI) {
        try launcherHwnd := UI.Hwnd
    }

    ; Primeiro tenta fechar educadamente qualquer janela visivel que nao seja
    ; o launcher nem parte basica do shell do Windows.
    for hwnd in WinGetList() {
        if (hwnd = launcherHwnd)
            continue

        try {
            if !DllCall("IsWindowVisible", "Ptr", hwnd, "Int")
                continue
        } catch {
            continue
        }

        className := ""
        processName := ""
        try className := WinGetClass("ahk_id " hwnd)
        try processName := StrLower(WinGetProcessName("ahk_id " hwnd))

        if (className = "Progman" || className = "WorkerW" || className = "Shell_TrayWnd" || className = "Shell_SecondaryTrayWnd")
            continue

        ; Nao fecha o desktop/Explorer base. Janelas normais abertas pelo aluno
        ; continuam sendo fechadas, inclusive Chrome, PowerPoint, jogos etc.
        if (processName = "explorer.exe" && (className = "CabinetWClass" || className = "ExploreWClass")) {
            try WinClose("ahk_id " hwnd)
            continue
        }

        try WinSetAlwaysOnTop(0, "ahk_id " hwnd)
        try WinClose("ahk_id " hwnd)
    }

    Sleep(700)

    ; Se alguma janela que a Nova Ordem Mundial abriu ignorar WinClose,
    ; encerra somente esses processos rastreados.
    for pid, _ in STUDENT_PIDS {
        if ProcessExist(pid) {
            try {
                RunWait(A_ComSpec " /c taskkill /PID " pid " /T /F", , "Hide")
            } catch {
            }
        }
    }

    StopWebGuardMonitor()
    SetTimer(MonitorExternal, 0)

    STUDENT_WINDOWS := Map()
    STUDENT_PIDS := Map()
    LAST_STUDENT_HWND := 0
    EXTERNAL_ACTIVE := false
    EXTERNAL_PID := 0
    EXTERNAL_HWND := 0
    EXTERNAL_TITLE := ""

    if IsObject(UI) {
        try {
            UI.Show("x0 y0 w" A_ScreenWidth " h" A_ScreenHeight)
            UI_VISIBLE := true
            WinActivate("ahk_id " UI.Hwnd)
        } catch {
        }
    }
}
