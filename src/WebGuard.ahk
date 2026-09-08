WebGuardEnabled() {
    global CFG
    return IniRead(CFG, "WebGuard", "Enabled", "1") = "1"
}

WebGuardPort() {
    global CFG

    try {
        port := Integer(IniRead(CFG, "WebGuard", "DebugPort", "9223"))
    } catch {
        port := 9223
    }

    if (port < 1024 || port > 65535)
        port := 9223

    return port
}

StudentChromeProfileDir() {
    base := EnvGet("LOCALAPPDATA")
    if (base = "")
        base := A_ScriptDir "\cache"

    dir := base "\NovaOrdemMundial\ChromeProfile"
    DirCreate(dir)
    return dir
}

IsBlockedWebUrl(url) {
    if !WebGuardEnabled()
        return false

    lower := StrLower(url)

    ; roblox.com + qualquer subdominio.
    if RegExMatch(lower, "(^|[/.])roblox\.com([/:?#]|$)")
        return true

    ; Qualquer URL contendo as duas palavras, em qualquer ordem.
    if InStr(lower, "love") && InStr(lower, "calculator")
        return true

    return false
}

StartWebGuardMonitor() {
    global WEB_GUARD_ACTIVE, WEB_GUARD_MISSES

    if !WebGuardEnabled()
        return

    WEB_GUARD_ACTIVE := true
    WEB_GUARD_MISSES := 0
    SetTimer(CheckBlockedChromeTargets, 250)
}

StopWebGuardMonitor() {
    global WEB_GUARD_ACTIVE, WEB_GUARD_MISSES

    WEB_GUARD_ACTIVE := false
    WEB_GUARD_MISSES := 0
    SetTimer(CheckBlockedChromeTargets, 0)
}

CheckBlockedChromeTargets() {
    global WEB_GUARD_ACTIVE, WEB_GUARD_MISSES

    if !WEB_GUARD_ACTIVE
        return

    port := WebGuardPort()
    body := HttpGetLocal("http://127.0.0.1:" port "/json/list")

    if (body = "") {
        WEB_GUARD_MISSES += 1
        if (WEB_GUARD_MISSES >= 12)
            StopWebGuardMonitor()
        return
    }

    WEB_GUARD_MISSES := 0
    q := Chr(34)
    pos := 1

    while RegExMatch(body, "s)\{(.*?)\}", &objectMatch, pos) {
        objectText := objectMatch[1]
        pos := objectMatch.Pos(0) + objectMatch.Len(0)

        if !RegExMatch(objectText, q "type" q "\s*:\s*" q "page" q)
            continue

        if !RegExMatch(objectText, q "id" q "\s*:\s*" q "(.*?)" q, &idMatch)
            continue

        if !RegExMatch(objectText, q "url" q "\s*:\s*" q "(.*?)" q, &urlMatch)
            continue

        targetId := idMatch[1]
        targetUrl := ChromeJsonUnescape(urlMatch[1])

        if IsBlockedWebUrl(targetUrl) {
            HttpGetLocal("http://127.0.0.1:" port "/json/close/" targetId)
        }
    }
}

ChromeJsonUnescape(text) {
    text := StrReplace(text, "\/", "/")
    text := StrReplace(text, "\u0026", "&")
    text := StrReplace(text, "\u003d", "=")
    text := StrReplace(text, "\u003D", "=")
    text := StrReplace(text, "\u002F", "/")
    text := StrReplace(text, "\u002f", "/")
    return text
}

HttpGetLocal(url) {
    try {
        req := ComObject("WinHttp.WinHttpRequest.5.1")
        req.SetTimeouts(150, 150, 150, 250)
        req.Open("GET", url, false)
        req.Send()

        if (req.Status >= 200 && req.Status < 300)
            return req.ResponseText
    } catch {
    }

    return ""
}

ShowBlockedNotice() {
    ToolTip("Site bloqueado no Modo Aluno", 20, 20)
    SetTimer(() => ToolTip(), -1700)
}

OpenStudentChromeSetup(*) {
    if !AskRestricted()
        return

    chrome := FindChrome()
    if (chrome = "") {
        MsgBox("Google Chrome nao encontrado.", "Modo Aluno")
        return
    }

    ; Atalho do professor para instalar uBlock/ajustar o perfil escolar.
    OpenChromeProfileUrl(
        chrome,
        "https://chromewebstore.google.com/search/uBlock%20Origin%20Lite",
        false
    )
}
