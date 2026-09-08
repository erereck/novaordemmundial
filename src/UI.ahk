BuildUI() {
    global UI, UI_VISIBLE, PAGE, CFG, EXTERNAL_ACTIVE, ASSETDIR

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

    wallpaperFile := IniRead(CFG, "General", "WallpaperFile", "")
    if (wallpaperFile != "") {
        wallpaperPath := ASSETDIR "\" wallpaperFile
        if FileExist(wallpaperPath) {
            try {
                UI.AddPicture("x0 y0 w" w " h" h, wallpaperPath)
            } catch {
            }
        }
    }

    if (PAGE = "games") {
        UI.SetFont("s28 Bold", "Segoe UI")
        UI.AddText("x0 y22 w" w " h42 Center cFFFFFF BackgroundTrans", "JOGOS")
        UI.SetFont("s12 Bold", "Segoe UI")
        UI.AddText("x0 y65 w" w " h24 Center cFFFFFF BackgroundTrans", "F1 ou ESC = voltar")
        AddGrid(ReadItems("Game"), 105)

        back := UI.AddButton("x25 y" (h - 62) " w170 h40", "<- VOLTAR")
        back.OnEvent("Click", (*) => ShowHome())
    } else {
        UI.SetFont("s29 Bold", "Segoe UI")
        UI.AddText("x0 y20 w" w " h44 Center cFFFFFF BackgroundTrans", title)
        UI.SetFont("s13 Bold", "Segoe UI")
        UI.AddText("x0 y64 w" w " h25 Center cFFFFFF BackgroundTrans", subtitle)

        items := ReadItems("Home")

        if (IniRead(CFG, "Special", "Enabled", "0") = "1") {
            items.InsertAt(1, Map(
                "Name", IniRead(CFG, "Special", "Name", "FAZER PROVA"),
                "Type", IniRead(CFG, "Special", "Type", "web"),
                "Target", IniRead(CFG, "Special", "Target", "https://example.com/prova"),
                "Protected", IniRead(CFG, "Special", "Protected", "0"),
                "IconFile", IniRead(CFG, "Special", "IconFile", "")
            ))
        }

        if (IniRead(CFG, "General", "GamesEnabled", "1") = "1") {
            items.Push(Map(
                "Name", "JOGOS",
                "Type", "page",
                "Target", "games",
                "Protected", "0",
                "IconFile", IniRead(CFG, "General", "GamesIconFile", "")
            ))
        }

        AddGrid(items, 105)

        UI.SetFont("s9 Bold", "Segoe UI")
        UI.AddText("x18 y" (h - 35) " w180 h20 cFFFFFF BackgroundTrans",
            "config v" IniRead(CFG, "General", "Version", "0"))
    }

    UI.SetFont("s10 Bold", "Segoe UI")
    exit := UI.AddButton("x" (w - 205) " y" (h - 62) " w180 h40", "PROFESSOR / SAIR")
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
    global UI, ASSETDIR

    if (items.Length = 0)
        return

    w := A_ScreenWidth
    h := A_ScreenHeight

    cols := items.Length > 6 ? 4 : 3
    if (w < 1050)
        cols := 3

    rows := Ceil(items.Length / cols)
    gapX := 20
    sideMargin := 70
    tileW := Floor((w - sideMargin * 2 - gapX * (cols - 1)) / cols)

    availableH := h - topY - 90
    rowH := Floor(availableH / rows)
    iconSize := Min(102, Max(54, rowH - 54))
    buttonH := 40

    totalW := cols * tileW + (cols - 1) * gapX
    startX := Floor((w - totalW) / 2)

    UI.SetFont("s13 Bold", "Segoe UI")

    for index, item in items {
        row := Floor((index - 1) / cols)
        col := Mod(index - 1, cols)
        tileX := startX + col * (tileW + gapX)
        tileY := topY + row * rowH

        iconFile := item.Has("IconFile") ? item["IconFile"] : ""
        iconPath := iconFile != "" ? ASSETDIR "\" iconFile : ""
        hasIcon := iconPath != "" && FileExist(iconPath)

        if hasIcon {
            iconX := tileX + Floor((tileW - iconSize) / 2)
            try {
                UI.AddPicture("x" iconX " y" tileY " w" iconSize " h" iconSize, iconPath)
            } catch {
                hasIcon := false
            }
        }

        label := item["Name"]
        if (item["Protected"] = "1")
            label .= "  [senha]"

        if hasIcon {
            by := tileY + iconSize + 5
            b := UI.AddButton("x" tileX " y" by " w" tileW " h" buttonH, label)
        } else {
            by := tileY + Max(4, Floor((rowH - 72) / 2))
            b := UI.AddButton("x" tileX " y" by " w" tileW " h72", label)
        }

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
            "Protected", IniRead(CFG, sec, "Protected", "0"),
            "IconFile", IniRead(CFG, sec, "IconFile", "")
        ))
    }

    return out
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
        "Protected", IniRead(CFG, "Special", "Protected", "0"),
        "IconFile", IniRead(CFG, "Special", "IconFile", "")
    ))
}
