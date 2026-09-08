#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent

SetWorkingDir(A_ScriptDir)

SETTINGS := A_ScriptDir "\settings.ini"
LOCALCFG := A_ScriptDir "\config.ini"
CACHEDIR := A_ScriptDir "\cache"
CACHECFG := CACHEDIR "\config.ini"

global CFG := LOCALCFG
global CFG_VERSION := "0"
global PAGE := "home"
global UI := 0
global UI_VISIBLE := false

global EXTERNAL_ACTIVE := false
global EXTERNAL_PID := 0
global EXTERNAL_HWND := 0

DirCreate(CACHEDIR)
OnExit(RestoreWindows)

; -------------------- BLOQUEIOS LEVES --------------------
LWin::Return
RWin::Return
^Esc::Return
^+Esc::Return
#r::Return
#x::Return
#d::Return
#e::Return
#i::Return
#s::Return
#a::Return
#Tab::Return
!Tab::Return
#^d::Return

; Professor
^!+F12::AskExit()

; Volta ao launcher mesmo depois de abrir um site/app.
F1::ShowHome()

#HotIf LauncherActive()
g::OpenHomeNamed("Google")
t::OpenHomeNamed("Tux Paint")
p::OpenHomeNamed("Poki")
l::OpenHomeNamed("TypingLand")
c::OpenHomeNamed("Canva")
o::OpenHomeNamed("PowerPoint")
F8::ShowGames()
F6::OpenSpecial()
Esc::GoBack()
!F4::AskExit()
#HotIf

; -------------------- START --------------------
HideTaskbar()
SyncNow()
ChooseConfig()
CFG_VERSION := IniRead(CFG, "General", "Version", "0")
BuildUI()

seconds := Integer(IniRead(SETTINGS, "Sync", "SyncSeconds", "10"))
if (seconds < 5)
    seconds := 5
SetTimer(CheckUpdate, seconds * 1000)

; -------------------- UI --------------------
BuildUI() {
    global UI, UI_VISIBLE, PAGE, CFG, EXTERNAL_ACTIVE

    if IsObject(UI) {
        try {
            UI.Destroy()
        } catch {
        }
    }

    title := IniRead(CFG, "General", "Title", "Modo Aluno")
    subtitle := IniRead(CFG, "General", "Subtitle", "Escolha uma atividade")
    w := A_ScreenWidth
    h := A_ScreenHeight

    UI := Gui("+AlwaysOnTop -Caption +ToolWindow", title)
    UI.BackColor := "20242A"
    UI.MarginX := 0
    UI.MarginY := 0

    if (PAGE = "games") {
        UI.SetFont("s30 Bold", "Segoe UI")
        UI.AddText("x0 y35 w" w " h45 Center cFFFFFF BackgroundTrans", "JOGOS")
        UI.SetFont("s13", "Segoe UI")
        UI.AddText("x0 y84 w" w " h28 Center cC9D1D9 BackgroundTrans", "F1 ou ESC = voltar")
        AddGrid(ReadItems("Game"), 145)

        back := UI.AddButton("x35 y" (h - 90) " w190 h52", "← VOLTAR")
        back.OnEvent("Click", (*) => ShowHome())
    } else {
        UI.SetFont("s31 Bold", "Segoe UI")
        UI.AddText("x0 y32 w" w " h50 Center cFFFFFF BackgroundTrans", title)
        UI.SetFont("s15", "Segoe UI")
        UI.AddText("x0 y85 w" w " h28 Center cC9D1D9 BackgroundTrans", subtitle)

        items := ReadItems("Home")

        if (IniRead(CFG, "Special", "Enabled", "0") = "1") {
            items.InsertAt(1, Map(
                "Name", IniRead(CFG, "Special", "Name", "FAZER PROVA"),
                "Type", IniRead(CFG, "Special", "Type", "web"),
                "Target", IniRead(CFG, "Special", "Target", "https://example.com/prova"),
                "Protected", IniRead(CFG, "Special", "Protected", "0")
            ))
        }

        if (IniRead(CFG, "General", "GamesEnabled", "1") = "1") {
            items.Push(Map("Name", "JOGOS", "Type", "page", "Target", "games", "Protected", "0"))
        }

        AddGrid(items, 145)

        UI.SetFont("s10", "Segoe UI")
        UI.AddText("x25 y" (h - 42) " w250 h25 c89929B BackgroundTrans", "config v" IniRead(CFG, "General", "Version", "0"))
    }

    UI.SetFont("s11 Bold", "Segoe UI")
    exit := UI.AddButton("x" (w - 225) " y" (h - 76) " w190 h46", "PROFESSOR / SAIR")
    exit.OnEvent("Click", (*) => AskExit())

    UI.Show("x0 y0 w" w " h" h)
    UI_VISIBLE := true

    if EXTERNAL_ACTIVE {
        try {
            UI.Opt("-AlwaysOnTop")
        } catch {
        }
    }
}

AddGrid(items, topY) {
    global UI
    w := A_ScreenWidth
    cols := 3
    gapX := 28
    gapY := 25
    bw := Min(330, Floor((w - 160 - gapX * 2) / cols))
    bh := 125
    total := cols * bw + (cols - 1) * gapX
    startX := Floor((w - total) / 2)

    UI.SetFont("s20 Bold", "Segoe UI")

    for index, item in items {
        row := Floor((index - 1) / cols)
        col := Mod(index - 1, cols)
        x := startX + col * (bw + gapX)
        y := topY + row * (bh + gapY)
        label := item["Name"]
        if (item["Protected"] = "1")
            label .= "`n[senha]"
        b := UI.AddButton("x" x " y" y " w" bw " h" bh, label)
        b.OnEvent("Click", RunItem.Bind(item))
    }
}

ReadItems(prefix) {
    global CFG
    out := []
    count := Integer(IniRead(CFG, "General", prefix "Count", "0"))
    Loop count {
        sec := prefix A_Index
        name := IniRead(CFG, sec, "Name", "")
        if (name = "")
            continue
        out.Push(Map(
            "Name", name,
            "Type", IniRead(CFG, sec, "Type", "web"),
            "Target", IniRead(CFG, sec, "Target", ""),
            "Protected", IniRead(CFG, sec, "Protected", "0")
        ))
    }
    return out
}

; -------------------- ABRIR ITENS --------------------
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
    global EXTERNAL_PID, EXTERNAL_HWND

    PrepareExternal()

    pid := 0
    try {
        Run(target, , , &pid)
    } catch {
        FinishExternal()
        MsgBox("Não consegui abrir:`n`n" target "`n`nEsse caminho ainda é placeholder.", "Modo Aluno")
        return
    }

    EXTERNAL_PID := pid
    EXTERNAL_HWND := 0
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
        MsgBox("Não consegui abrir:`n" url, "Modo Aluno")
        return
    }

    EXTERNAL_PID := pid
    EXTERNAL_HWND := 0

    if (chrome != "") {
        Loop 12 {
            Sleep(200)
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
    global UI, UI_VISIBLE, EXTERNAL_ACTIVE, EXTERNAL_PID, EXTERNAL_HWND

    EXTERNAL_ACTIVE := true
    EXTERNAL_PID := 0
    EXTERNAL_HWND := 0

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
    global EXTERNAL_ACTIVE, EXTERNAL_PID, EXTERNAL_HWND

    if !EXTERNAL_ACTIVE {
        SetTimer(MonitorExternal, 0)
        return
    }

    if EXTERNAL_HWND {
        if !WinExist("ahk_id " EXTERNAL_HWND) {
            FinishExternal()
        }
        return
    }

    if EXTERNAL_PID {
        if !ProcessExist(EXTERNAL_PID) {
            FinishExternal()
        }
    }
}

FinishExternal() {
    global UI, UI_VISIBLE, EXTERNAL_ACTIVE, EXTERNAL_PID, EXTERNAL_HWND

    SetTimer(MonitorExternal, 0)
    EXTERNAL_ACTIVE := false
    EXTERNAL_PID := 0
    EXTERNAL_HWND := 0

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
    global EXTERNAL_ACTIVE, EXTERNAL_PID, EXTERNAL_HWND

    SetTimer(MonitorExternal, 0)
    EXTERNAL_ACTIVE := false
    EXTERNAL_PID := 0
    EXTERNAL_HWND := 0
}

ShowHome() {
    global PAGE
    CancelExternalMonitor()
    PAGE := "home"
    BuildUI()
}

ShowGames() {
    global PAGE, CFG
    if !LauncherActive()
        return
    if (IniRead(CFG, "General", "GamesEnabled", "1") != "1")
        return
    PAGE := "games"
    BuildUI()
}

GoBack() {
    global PAGE
    if (PAGE = "games")
        ShowHome()
}

OpenSpecial() {
    global CFG
    if (IniRead(CFG, "Special", "Enabled", "0") != "1")
        return
    RunItem(Map(
        "Name", IniRead(CFG, "Special", "Name", "FAZER PROVA"),
        "Type", IniRead(CFG, "Special", "Type", "web"),
        "Target", IniRead(CFG, "Special", "Target", "https://example.com/prova"),
        "Protected", IniRead(CFG, "Special", "Protected", "0")
    ))
}

; -------------------- SENHAS --------------------
PromptPassword(prompt, title) {
    global UI, EXTERNAL_ACTIVE

    if IsObject(UI) {
        try {
            UI.Opt("-AlwaysOnTop")
        } catch {
        }
    }

    SetTimer(ForceDialogFront.Bind(title), -100)
    result := InputBox(prompt, title, "Password w390 h145")

    if IsObject(UI) && !EXTERNAL_ACTIVE {
        try {
            UI.Opt("+AlwaysOnTop")
        } catch {
        }
    }

    return result
}

ForceDialogFront(title) {
    hwnd := WinExist(title)
    if !hwnd
        return

    try {
        WinSetAlwaysOnTop(1, "ahk_id " hwnd)
    } catch {
    }

    try {
        WinActivate("ahk_id " hwnd)
    } catch {
    }
}

AskRestricted() {
    global CFG
    expected := IniRead(CFG, "Security", "RestrictedPassword", "4321")
    r := PromptPassword("Digite a senha do professor:", "Conteúdo restrito")

    if (r.Result != "OK")
        return false

    if (r.Value != expected) {
        MsgBox("Senha incorreta.", "Modo Aluno")
        return false
    }

    return true
}

AskExit(*) {
    global CFG
    expected := IniRead(CFG, "Security", "ExitPassword", "1234")
    r := PromptPassword("Digite a senha do professor para encerrar:", "Professor")

    if (r.Result != "OK")
        return

    if (r.Value != expected) {
        MsgBox("Senha incorreta.", "Modo Aluno")
        return
    }

    RestoreWindows()
    ExitApp()
}

; -------------------- SYNC --------------------
SyncNow() {
    global SETTINGS, CACHECFG, CACHEDIR
    url := IniRead(SETTINGS, "Sync", "RemoteConfigURL", "")
    if (url = "")
        return false

    temp := CACHEDIR "\download.tmp.ini"

    try {
        if FileExist(temp)
            FileDelete(temp)

        Download(url, temp)

        if (IniRead(temp, "General", "Version", "") = "")
            throw Error("config inválido")

        if (IniRead(temp, "General", "Title", "") = "")
            throw Error("config inválido")

        FileCopy(temp, CACHECFG, true)
        FileDelete(temp)
        return true
    } catch {
        if FileExist(temp) {
            try {
                FileDelete(temp)
            } catch {
            }
        }
        return false
    }
}

ChooseConfig() {
    global CFG, CACHECFG, LOCALCFG
    CFG := FileExist(CACHECFG) ? CACHECFG : LOCALCFG
}

CheckUpdate() {
    global CFG, CACHECFG, CFG_VERSION

    if !SyncNow()
        return

    newVersion := IniRead(CACHECFG, "General", "Version", "0")
    if (newVersion = CFG_VERSION)
        return

    CFG := CACHECFG
    CFG_VERSION := newVersion

    if LauncherActive()
        BuildUI()
}

; -------------------- WINDOWS --------------------
HideTaskbar() {
    try {
        WinHide("ahk_class Shell_TrayWnd")
    } catch {
    }

    try {
        for hwnd in WinGetList("ahk_class Shell_SecondaryTrayWnd") {
            WinHide("ahk_id " hwnd)
        }
    } catch {
    }
}

ShowTaskbar() {
    try {
        WinShow("ahk_class Shell_TrayWnd")
    } catch {
    }

    try {
        for hwnd in WinGetList("ahk_class Shell_SecondaryTrayWnd") {
            WinShow("ahk_id " hwnd)
        }
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
