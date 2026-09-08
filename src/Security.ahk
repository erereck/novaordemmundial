PromptAccess(prompt, title) {
    global UI, EXTERNAL_ACTIVE

    if IsObject(UI) {
        try UI.Opt("-AlwaysOnTop")
    }

    SetTimer(ForceAccessFront.Bind(title), -120)
    result := InputBox(prompt, title, "Password w390 h145")

    if IsObject(UI) && !EXTERNAL_ACTIVE {
        try UI.Opt("+AlwaysOnTop")
    }

    return result
}

ForceAccessFront(title) {
    hwnd := WinExist(title)
    if !hwnd
        return

    try WinSetAlwaysOnTop(1, "ahk_id " hwnd)
    try WinActivate("ahk_id " hwnd)
}

AskRestricted() {
    global CFG

    expected := IniRead(CFG, "Security", "RestrictedPassword", "")
    r := PromptAccess("Digite a senha do professor:", "Conteudo restrito")

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

    expected := IniRead(CFG, "Security", "ExitPassword", "")
    r := PromptAccess("Digite a senha do professor para encerrar:", "Professor")

    if (r.Result != "OK")
        return

    if (r.Value != expected) {
        MsgBox("Senha incorreta.", "Modo Aluno")
        return
    }

    RestoreWindows()
    ExitApp()
}
