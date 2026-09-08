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
    global EXTERNAL_PID, EXTERNAL_HWND, UI

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

    Loop 15 {
        Sleep(150)
        hwnd := WinActive("A")
        if hwnd {
            if !IsObject(UI) || hwnd != UI.Hwnd {
                EXTERNAL_HWND := hwnd
                break
            }
        }
    }

    SetTimer(MonitorExternal, 500)
}

OpenWeb(url) {
    global EXTERNAL_PID, EXTERNAL_HWND

    if (url = "")
        return

    PrepareExternal()
    chrome := FindChrome()
    before := Map()

    if (chrome != "") {
        for hwnd in WinGetList("ahk_exe chrome.exe")
            before[hwnd] := true
    }

    pid := 0

    try {
        if (chrome != "") {
            q := Chr(34)
            Run(q chrome q " --app=" q url q " --new-window", , , &pid)
        } else {
            Run(url, , , &pid)
        }
    } catch {
        FinishExternal()
        MsgBox("Nao consegui abrir:`n" url, "Modo Aluno")
        return
    }

    EXTERNAL_PID := pid
    EXTERNAL_HWND := 0

    if (chrome != "") {
        Loop 16 {
            Sleep(180)
            for hwnd in WinGetList("ahk_exe chrome.exe") {
                if !before.Has(hwnd) {
                    EXTERNAL_HWND := hwnd
                    break
                }
            }
            if EXTERNAL_HWND
                break
        }

        if !EXTERNAL_HWND {
            activeChrome := WinActive("ahk_exe chrome.exe")
            if activeChrome
                EXTERNAL_HWND := activeChrome
        }
    }

    SetTimer(MonitorExternal, 500)
}

OpenStoreApp(name) {
    global EXTERNAL_TITLE

    if (name = "")
        return

    PrepareExternal()
    found := false

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

    if !found {
        FinishExternal()
        MsgBox("Nao achei o aplicativo '" name "' instalado pela Microsoft Store.", "Modo Aluno")
        return
    }

    EXTERNAL_TITLE := name
    SetTimer(MonitorExternal, 500)
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

PrepareExternal() {
    global UI, UI_VISIBLE, EXTERNAL_ACTIVE, EXTERNAL_PID, EXTERNAL_HWND, EXTERNAL_TITLE, EXTERNAL_STARTED

    EXTERNAL_ACTIVE := true
    EXTERNAL_PID := 0
    EXTERNAL_HWND := 0
    EXTERNAL_TITLE := ""
    EXTERNAL_STARTED := A_TickCount

    if IsObject(UI) {
        try {
            UI.Opt("-AlwaysOnTop")
        } catch {
        }
        try {
            UI.Show("NoActivate x0 y0 w" A_ScreenWidth " h" A_ScreenHeight)
            UI_VISIBLE := true
        } catch {
        }
    }
}

MonitorExternal() {
    global EXTERNAL_ACTIVE, EXTERNAL_PID, EXTERNAL_HWND, EXTERNAL_TITLE, EXTERNAL_STARTED

    if !EXTERNAL_ACTIVE {
        SetTimer(MonitorExternal, 0)
        return
    }

    if EXTERNAL_HWND {
        if !WinExist("ahk_id " EXTERNAL_HWND)
            FinishExternal()
        return
    }

    if (EXTERNAL_TITLE != "") {
        hwnd := WinExist(EXTERNAL_TITLE)
        if hwnd {
            EXTERNAL_HWND := hwnd
            return
        }

        if ((A_TickCount - EXTERNAL_STARTED) < 15000)
            return

        EXTERNAL_TITLE := ""
        return
    }

    if EXTERNAL_PID {
        if !ProcessExist(EXTERNAL_PID)
            FinishExternal()
    }
}

FinishExternal() {
    global UI, UI_VISIBLE, EXTERNAL_ACTIVE, EXTERNAL_PID, EXTERNAL_HWND, EXTERNAL_TITLE

    SetTimer(MonitorExternal, 0)
    EXTERNAL_ACTIVE := false
    EXTERNAL_PID := 0
    EXTERNAL_HWND := 0
    EXTERNAL_TITLE := ""

    if IsObject(UI) {
        try {
            UI.Opt("+AlwaysOnTop")
        } catch {
        }
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

    SetTimer(MonitorExternal, 0)
    EXTERNAL_ACTIVE := false
    EXTERNAL_PID := 0
    EXTERNAL_HWND := 0
    EXTERNAL_TITLE := ""
}
