ProgramVersionLocal() {
    versionFile := A_ScriptDir "\version.txt"

    if !FileExist(versionFile)
        return 0

    try {
        return Integer(Trim(FileRead(versionFile, "UTF-8")))
    } catch {
        return 0
    }
}

CheckForProgramUpdate() {
    updater := A_ScriptDir "\updater.ps1"
    if !FileExist(updater)
        return false

    remoteText := HttpGetUpdateText(
        "https://raw.githubusercontent.com/erereck/novaordemmundial/main/version.txt"
    )

    if (remoteText = "")
        return false

    try {
        remoteVersion := Integer(Trim(remoteText))
    } catch {
        return false
    }

    localVersion := ProgramVersionLocal()
    if (remoteVersion <= localVersion)
        return false

    pid := DllCall("GetCurrentProcessId")
    q := Chr(34)
    cmd := "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "
        . q updater q
        . " -Root " q A_ScriptDir q
        . " -PidToWait " pid

    try {
        Run(cmd, , "Hide")
        return true
    } catch {
        return false
    }
}

AutoUpdateTick() {
    global EXTERNAL_ACTIVE, STUDENT_WINDOWS, STUDENT_PIDS

    ; Nunca atualiza no meio de um jogo, site ou programa aberto.
    if EXTERNAL_ACTIVE
        return

    if (STUDENT_WINDOWS.Count > 0 || STUDENT_PIDS.Count > 0)
        return

    if CheckForProgramUpdate()
        ExitApp()
}

HttpGetUpdateText(url) {
    try {
        req := ComObject("WinHttp.WinHttpRequest.5.1")
        req.SetTimeouts(1000, 1000, 1500, 2000)
        req.Open("GET", url, false)
        req.SetRequestHeader("Cache-Control", "no-cache")
        req.Send()

        if (req.Status >= 200 && req.Status < 300)
            return req.ResponseText
    } catch {
    }

    return ""
}
