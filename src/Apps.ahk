RunItem(item, *) {
    global PAGE

    if (item["Protected"] = "1" && !AskRestricted())
        return

    type := StrLower(item["Type"])
    target := item["Target"]

    if (type = "page") {
        PAGE := target
        BuildUI()
        return
    }

    if (type = "web") {
        OpenWeb(target)
        return
    }

    if (type = "exe" || type = "command") {
        OpenProgram(target)
        return
    }

    if (type = "store") {
        OpenStoreApp(target)
        return
    }

    MsgBox("Tipo desconhecido: " type, "Modo Aluno")
}

OpenHomeNamed(name) {
    for _, item in ReadItems("Home") {
        if (item["Name"] = name) {
            RunItem(item)
            return
        }
    }
}

OpenProgram(target) {
    global EXTERNAL_PID, EXTERNAL_HWND, STUDENT_PIDS

    before := SnapshotWindows()
    PrepareExternal()

    pid := 0
    try {
        Run(target, , , &pid)
    } catch {
        FinishExternal()
        MsgBox("Nao consegui abrir:`n`n" target, "Modo Aluno")
        return
    }

    EXTERNAL_PID := pid
    EXTERNAL_HWND := 0

    if pid
        STUDENT_PIDS[pid] := true

    hwnd := WaitForExternalWindow(before, pid, 5000)
    if hwnd
        RegisterStudentWindow(hwnd, pid)

    SetTimer(MonitorExternal, 400)
}

OpenWeb(url) {
    if (url = "")
        return

    if IsBlockedWebUrl(url) {
        ShowBlockedNotice()
        return
    }

    chrome := FindChrome()
    if (chrome = "") {
        MsgBox("Google Chrome nao encontrado neste computador.", "Modo Aluno")
        return
    }

    OpenChromeProfileUrl(chrome, url, true)
}

OpenChromeProfileUrl(chrome, url, appMode := true) {
    global EXTERNAL_PID, EXTERNAL_HWND, STUDENT_PIDS

    before := SnapshotWindows()
    PrepareExternal()

    profile := StudentChromeProfileDir()
    port := WebGuardPort()
    q := Chr(34)

    cmd := q chrome q
        . " --user-data-dir=" q profile q
        . " --remote-debugging-address=127.0.0.1"
        . " --remote-debugging-port=" port
        . " --no-first-run --no-default-browser-check"

    if appMode
        cmd .= " --app=" q url q " --new-window"
    else
        cmd .= " --new-window " q url q

    pid := 0

    try {
        Run(cmd, , , &pid)
    } catch {
        FinishExternal()
        MsgBox("Nao consegui abrir o Chrome.", "Modo Aluno")
        return
    }

    EXTERNAL_PID := pid
    EXTERNAL_HWND := 0

    if pid
        STUDENT_PIDS[pid] := true

    StartWebGuardMonitor()

    hwnd := WaitForExternalWindow(before, pid, 6000)
    if hwnd
        RegisterStudentWindow(hwnd, pid)

    SetTimer(MonitorExternal, 400)
}

OpenStoreApp(name) {
    global EXTERNAL_TITLE

    if (name = "")
        return

    compactName := StrLower(StrReplace(name, " ", ""))
    if (compactName = "typingland") {
        OpenTypingLandDedicated()
        return
    }

    before := SnapshotWindows()
    PrepareExternal()
    found := false

    ; Caminho principal: pergunta ao proprio Windows qual AppUserModelID foi
    ; registrado no menu Iniciar e abre por shell:AppsFolder\<AppID>.
    appId := ResolveStoreAppId(name)
    if (appId != "") {
        q := Chr(34)
        try {
            Run("explorer.exe " q "shell:AppsFolder\" appId q)
            found := true
        } catch {
            found := false
        }
    }

    ; Fallback para maquinas em que Get-StartApps nao devolva o aplicativo.
    if !found {
        try {
            shell := ComObject("Shell.Application")
            folder := shell.Namespace("shell:AppsFolder")

            if folder {
                for item in folder.Items {
                    if InStr(StrLower(item.Name), StrLower(name)) {
                        item.InvokeVerb("open")
                        found := true
                        break
                    }
                }
            }
        } catch {
            found := false
        }
    }

    if !found {
        FinishExternal()
        MsgBox("Nao achei o aplicativo '" name "' instalado neste Windows.", "Modo Aluno")
        return
    }

    ; UWP/MSIX costuma ser iniciado por um processo intermediario, entao nao
    ; confiamos em PID. Detectamos a janela nova e aplicamos as mesmas regras
    ; de qualquer app: maximizada + topmost.
    EXTERNAL_TITLE := name
    hwnd := WaitForExternalWindow(before, 0, 9000)

    if !hwnd
        hwnd := FindWindowByTitleNeedle(name)

    if hwnd {
        RegisterStudentWindow(hwnd)
        EXTERNAL_TITLE := ""
    }

    SetTimer(MonitorExternal, 400)
}

OpenTypingLandDedicated() {
    global EXTERNAL_PID, EXTERNAL_HWND, STUDENT_PIDS

    script := A_ScriptDir "\tools\open-typingland.ps1"
    if !FileExist(script) {
        MsgBox("Launcher do Typing Land nao encontrado.`n`n" script, "Modo Aluno")
        return
    }

    before := SnapshotWindows()
    PrepareExternal()

    q := Chr(34)
    cmd := "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File " q script q
    pid := 0

    try {
        Run(cmd, , "Hide", &pid)
    } catch {
        FinishExternal()
        MsgBox("Nao consegui iniciar o launcher do Typing Land.", "Modo Aluno")
        return
    }

    EXTERNAL_PID := pid
    EXTERNAL_HWND := 0
    if pid
        STUDENT_PIDS[pid] := true

    hwnd := WaitForExternalWindow(before, 0, 15000)

    if !hwnd
        hwnd := FindWindowByTitleNeedle("Typing")

    if hwnd {
        RegisterStudentWindow(hwnd)
        SetTimer(MonitorExternal, 400)
        return
    }

    if pid && STUDENT_PIDS.Has(pid)
        STUDENT_PIDS.Delete(pid)
    EXTERNAL_PID := 0
    FinishExternal()

    debugPath := EnvGet("LOCALAPPDATA") "\NovaOrdemMundial\typingland-debug.txt"
    if FileExist(debugPath) {
        MsgBox(
            "O Windows nao conseguiu abrir o Typing Land.`n`nFoi criado um diagnostico em:`n" debugPath "`n`nMe envie esse arquivo e eu cravo o AppID exato.",
            "Typing Land"
        )
    } else {
        MsgBox(
            "O Typing Land nao abriu e o Windows nao retornou uma janela.`n`nConfirme se ele abre normalmente pelo Menu Iniciar.",
            "Typing Land"
        )
    }
}

ResolveStoreAppId(name) {
    script := A_ScriptDir "\tools\resolve-store-app.ps1"
    if !FileExist(script)
        return ""

    q := Chr(34)
    safeName := StrReplace(name, q, "")
    cmd := "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "
        . q script q
        . " -Name " q safeName q

    try {
        ws := ComObject("WScript.Shell")
        exec := ws.Exec(cmd)
        deadline := A_TickCount + 6000

        while (exec.Status = 0 && A_TickCount < deadline)
            Sleep(50)

        if (exec.Status = 0) {
            try exec.Terminate()
            return ""
        }

        appId := Trim(exec.StdOut.ReadAll(), " `t`r`n")
        return appId
    } catch {
        return ""
    }
}

FindChrome() {
    paths := [A_ProgramFiles "\Google\Chrome\Application\chrome.exe"]

    pf86 := EnvGet("ProgramFiles(x86)")
    if (pf86 != "")
        paths.Push(pf86 "\Google\Chrome\Application\chrome.exe")

    localAppData := EnvGet("LOCALAPPDATA")
    if (localAppData != "")
        paths.Push(localAppData "\Google\Chrome\Application\chrome.exe")

    for _, p in paths {
        if FileExist(p)
            return p
    }

    return ""
}

SnapshotWindows() {
    snapshot := Map()
    for hwnd in WinGetList()
        snapshot[hwnd] := true
    return snapshot
}

WaitForExternalWindow(before, preferredPid := 0, timeoutMs := 5000) {
    loops := Max(1, Ceil(timeoutMs / 125))

    Loop loops {
        Sleep(125)

        if preferredPid {
            try {
                for hwnd in WinGetList("ahk_pid " preferredPid) {
                    if IsStudentWindowCandidate(hwnd)
                        return hwnd
                }
            } catch {
            }
        }

        for hwnd in WinGetList() {
            if before.Has(hwnd)
                continue

            if IsStudentWindowCandidate(hwnd)
                return hwnd
        }
    }

    return 0
}

IsStudentWindowCandidate(hwnd) {
    global UI

    if !hwnd
        return false

    if IsObject(UI) {
        try {
            if (hwnd = UI.Hwnd)
                return false
        } catch {
        }
    }

    try {
        if !DllCall("IsWindowVisible", "Ptr", hwnd, "Int")
            return false
    } catch {
        return false
    }

    title := ""
    try title := WinGetTitle("ahk_id " hwnd)
    if (title = "")
        return false

    className := ""
    try className := WinGetClass("ahk_id " hwnd)

    if (className = "Progman" || className = "WorkerW" || className = "Shell_TrayWnd" || className = "Shell_SecondaryTrayWnd")
        return false

    return true
}

RegisterStudentWindow(hwnd, pid := 0) {
    global STUDENT_WINDOWS, STUDENT_PIDS, LAST_STUDENT_HWND
    global EXTERNAL_ACTIVE, EXTERNAL_HWND, EXTERNAL_PID

    if !IsStudentWindowCandidate(hwnd)
        return false

    STUDENT_WINDOWS[hwnd] := true
    if pid
        STUDENT_PIDS[pid] := true

    LAST_STUDENT_HWND := hwnd
    EXTERNAL_ACTIVE := true
    EXTERNAL_HWND := hwnd
    if pid
        EXTERNAL_PID := pid

    try WinMaximize("ahk_id " hwnd)
    try WinSetAlwaysOnTop(1, "ahk_id " hwnd)
    try WinActivate("ahk_id " hwnd)

    return true
}

PrepareExternal() {
    global UI, UI_VISIBLE, EXTERNAL_ACTIVE, EXTERNAL_PID, EXTERNAL_HWND, EXTERNAL_TITLE, EXTERNAL_STARTED

    EXTERNAL_ACTIVE := true
    EXTERNAL_PID := 0
    EXTERNAL_HWND := 0
    EXTERNAL_TITLE := ""
    EXTERNAL_STARTED := A_TickCount

    ; O launcher continua existindo em tela cheia, mas ao abrir qualquer coisa
    ; perde o topmost e fica definitivamente por baixo da sessao do aluno.
    if IsObject(UI) {
        try UI.Opt("-AlwaysOnTop")
        try {
            UI.Show("NoActivate x0 y0 w" A_ScreenWidth " h" A_ScreenHeight)
            UI_VISIBLE := true
        } catch {
        }
    }
}

MonitorExternal() {
    global STUDENT_WINDOWS, STUDENT_PIDS, EXTERNAL_TITLE, EXTERNAL_STARTED

    deadWindows := []
    for hwnd, _ in STUDENT_WINDOWS {
        if !WinExist("ahk_id " hwnd) {
            deadWindows.Push(hwnd)
            continue
        }

        ; Janela de aluno nao pode cair atras do launcher.
        try WinSetAlwaysOnTop(1, "ahk_id " hwnd)

        ; A regra da v5 e sempre abrir/manter maximizado.
        try {
            if (WinGetMinMax("ahk_id " hwnd) != 1)
                WinMaximize("ahk_id " hwnd)
        } catch {
        }
    }

    for _, hwnd in deadWindows
        STUDENT_WINDOWS.Delete(hwnd)

    deadPids := []
    for pid, _ in STUDENT_PIDS {
        if !ProcessExist(pid) {
            deadPids.Push(pid)
            continue
        }

        try {
            for hwnd in WinGetList("ahk_pid " pid) {
                if !STUDENT_WINDOWS.Has(hwnd) && IsStudentWindowCandidate(hwnd)
                    RegisterStudentWindow(hwnd, pid)
            }
        } catch {
        }
    }

    for _, pid in deadPids
        STUDENT_PIDS.Delete(pid)

    if (EXTERNAL_TITLE != "") {
        hwnd := FindWindowByTitleNeedle(EXTERNAL_TITLE)
        if hwnd {
            RegisterStudentWindow(hwnd)
            EXTERNAL_TITLE := ""
        } else if ((A_TickCount - EXTERNAL_STARTED) > 15000) {
            EXTERNAL_TITLE := ""
        }
    }

    if (STUDENT_WINDOWS.Count = 0 && STUDENT_PIDS.Count = 0 && EXTERNAL_TITLE = "")
        FinishExternal()
}

FindWindowByTitleNeedle(needle) {
    lowerNeedle := StrLower(needle)

    for hwnd in WinGetList() {
        if !IsStudentWindowCandidate(hwnd)
            continue

        title := ""
        try title := WinGetTitle("ahk_id " hwnd)

        if InStr(StrLower(title), lowerNeedle)
            return hwnd
    }

    return 0
}

FinishExternal() {
    global UI, UI_VISIBLE, EXTERNAL_ACTIVE, EXTERNAL_PID, EXTERNAL_HWND, EXTERNAL_TITLE
    global STUDENT_WINDOWS, STUDENT_PIDS, LAST_STUDENT_HWND

    if (STUDENT_WINDOWS.Count > 0 || STUDENT_PIDS.Count > 0 || EXTERNAL_TITLE != "")
        return

    SetTimer(MonitorExternal, 0)
    EXTERNAL_ACTIVE := false
    EXTERNAL_PID := 0
    EXTERNAL_HWND := 0
    EXTERNAL_TITLE := ""
    LAST_STUDENT_HWND := 0

    if IsObject(UI) {
        try {
            UI.Show("x0 y0 w" A_ScreenWidth " h" A_ScreenHeight)
            UI_VISIBLE := true
            WinActivate("ahk_id " UI.Hwnd)
        } catch {
        }
    }
}

CancelExternalMonitor() {
    global EXTERNAL_ACTIVE, EXTERNAL_PID, EXTERNAL_HWND, EXTERNAL_TITLE
    global STUDENT_WINDOWS, STUDENT_PIDS, LAST_STUDENT_HWND

    ; ShowHome/F1 pode chamar isto. Se ainda existe alguma coisa aberta,
    ; NAO desmonta a protecao: o launcher continua atras e a janela externa
    ; continua maximizada/topmost.
    if (STUDENT_WINDOWS.Count > 0 || STUDENT_PIDS.Count > 0 || EXTERNAL_TITLE != "")
        return

    SetTimer(MonitorExternal, 0)
    EXTERNAL_ACTIVE := false
    EXTERNAL_PID := 0
    EXTERNAL_HWND := 0
    EXTERNAL_TITLE := ""
    LAST_STUDENT_HWND := 0
    STUDENT_WINDOWS := Map()
    STUDENT_PIDS := Map()
}
