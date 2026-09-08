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
    scale := UIScale()

    ; -DPIScale e importante aqui: em notebooks com Windows em 125%/150%
    ; os controles nao podem crescer para fora da tela.
    UI := Gui("+AlwaysOnTop -Caption +ToolWindow -DPIScale", title)
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

    headerY := Max(10, Round(18 * scale))
    titleH := Max(30, Round(42 * scale))
    subtitleY := headerY + titleH
    subtitleH := Max(20, Round(25 * scale))
    gridTop := subtitleY + subtitleH + Max(8, Round(10 * scale))

    if (PAGE = "games") {
        UI.SetFont("s" ClampInt(Round(26 * scale), 16, 30) " Bold", "Segoe UI")
        UI.AddText("x0 y" headerY " w" w " h" titleH " Center cFFFFFF BackgroundTrans", "JOGOS")

        UI.SetFont("s" ClampInt(Round(11 * scale), 8, 13) " Bold", "Segoe UI")
        UI.AddText("x0 y" subtitleY " w" w " h" subtitleH " Center cFFFFFF BackgroundTrans", "F1 ou ESC = voltar")

        AddGrid(ReadItems("Game"), gridTop)

        footerH := FooterHeight()
        backW := Max(120, Round(165 * scale))
        backH := Max(30, Round(38 * scale))
        back := UI.AddButton("x" Max(12, Round(20 * scale)) " y" (h - footerH + Floor((footerH - backH) / 2)) " w" backW " h" backH, "<- VOLTAR")
        back.OnEvent("Click", (*) => ShowHome())
    } else {
        UI.SetFont("s" ClampInt(Round(27 * scale), 17, 31) " Bold", "Segoe UI")
        UI.AddText("x0 y" headerY " w" w " h" titleH " Center cFFFFFF BackgroundTrans", title)

        UI.SetFont("s" ClampInt(Round(12 * scale), 8, 14) " Bold", "Segoe UI")
        UI.AddText("x0 y" subtitleY " w" w " h" subtitleH " Center cFFFFFF BackgroundTrans", subtitle)

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

        AddGrid(items, gridTop)

        UI.SetFont("s" ClampInt(Round(8 * scale), 7, 10) " Bold", "Segoe UI")
        UI.AddText("x" Max(10, Round(15 * scale)) " y" (h - FooterHeight() + 6) " w160 h18 cFFFFFF BackgroundTrans",
            "config v" IniRead(CFG, "General", "Version", "0"))
    }

    footerH := FooterHeight()
    exitW := Max(145, Round(180 * scale))
    exitH := Max(30, Round(38 * scale))
    exitX := w - exitW - Max(12, Round(20 * scale))
    exitY := h - footerH + Floor((footerH - exitH) / 2)

    UI.SetFont("s" ClampInt(Round(9 * scale), 8, 11) " Bold", "Segoe UI")
    exit := UI.AddButton("x" exitX " y" exitY " w" exitW " h" exitH, "PROFESSOR / SAIR")
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
    scale := UIScale()
    footerH := FooterHeight()

    sideMargin := Max(16, Round(48 * scale))
    gapX := Max(8, Round(16 * scale))
    gapY := Max(4, Round(8 * scale))
    availableW := w - sideMargin * 2
    availableH := h - topY - footerH - Max(6, Round(8 * scale))

    ; Escolhe automaticamente a maior quantidade de colunas que ainda deixa
    ; cada bloco utilizavel. Quanto mais colunas, menos linhas e menos risco
    ; de estourar verticalmente em notebook baixo.
    cols := ChooseColumnCount(items.Length, availableW, availableH, gapX, gapY)
    rows := Ceil(items.Length / cols)

    tileW := Floor((availableW - gapX * (cols - 1)) / cols)
    rowH := Floor((availableH - gapY * (rows - 1)) / rows)

    ; Tudo deriva da altura REAL disponivel da linha.
    buttonH := ClampInt(Floor(rowH * 0.30), 28, Max(28, Round(42 * scale)))
    labelFont := ClampInt(Round(Min(13 * scale, buttonH * 0.30)), 8, 13)
    iconMaxByHeight := rowH - buttonH - Max(5, Round(7 * scale))
    iconMaxByWidth := tileW - Max(10, Round(16 * scale))
    iconSize := ClampInt(Min(iconMaxByHeight, iconMaxByWidth, Round(100 * scale)), 24, 100)

    ; Em tela absurdamente baixa, prioriza caber: some com o icone e deixa
    ; somente botoes compactos ao inves de jogar controles para fora.
    showIcons := rowH >= 68 && iconSize >= 28

    totalW := cols * tileW + (cols - 1) * gapX
    startX := Floor((w - totalW) / 2)

    UI.SetFont("s" labelFont " Bold", "Segoe UI")

    for index, item in items {
        row := Floor((index - 1) / cols)
        col := Mod(index - 1, cols)
        tileX := startX + col * (tileW + gapX)
        tileY := topY + row * (rowH + gapY)

        iconFile := item.Has("IconFile") ? item["IconFile"] : ""
        iconPath := iconFile != "" ? ASSETDIR "\" iconFile : ""
        hasIcon := showIcons && iconPath != "" && FileExist(iconPath)

        if hasIcon {
            iconX := tileX + Floor((tileW - iconSize) / 2)
            iconY := tileY + Max(0, Floor((rowH - iconSize - buttonH - 4) / 2))
            try {
                UI.AddPicture("x" iconX " y" iconY " w" iconSize " h" iconSize, iconPath)
            } catch {
                hasIcon := false
            }
        }

        label := item["Name"]
        if (item["Protected"] = "1")
            label .= " [senha]"

        if hasIcon {
            by := tileY + rowH - buttonH
            b := UI.AddButton("x" tileX " y" by " w" tileW " h" buttonH, label)
        } else {
            compactH := ClampInt(Floor(rowH * 0.62), 30, 58)
            by := tileY + Floor((rowH - compactH) / 2)
            b := UI.AddButton("x" tileX " y" by " w" tileW " h" compactH, label)
        }

        b.OnEvent("Click", RunItem.Bind(item))
    }
}

ChooseColumnCount(itemCount, availableW, availableH, gapX, gapY) {
    if (itemCount <= 0)
        return 1

    maxCols := Min(itemCount, 6)
    minTileW := 135
    minRowH := 78

    ; Primeiro tenta caber com blocos confortaveis.
    Loop maxCols {
        cols := maxCols - A_Index + 1
        rows := Ceil(itemCount / cols)
        tileW := Floor((availableW - gapX * (cols - 1)) / cols)
        rowH := Floor((availableH - gapY * (rows - 1)) / rows)

        if (tileW >= minTileW && rowH >= minRowH)
            return cols
    }

    ; Se a tela for muito pequena, prioriza o que gera a maior area por item.
    bestCols := 1
    bestScore := -1

    Loop maxCols {
        cols := A_Index
        rows := Ceil(itemCount / cols)
        tileW := Floor((availableW - gapX * (cols - 1)) / cols)
        rowH := Floor((availableH - gapY * (rows - 1)) / rows)

        if (tileW <= 0 || rowH <= 0)
            continue

        score := Min(tileW / 135.0, rowH / 78.0)
        if (score > bestScore) {
            bestScore := score
            bestCols := cols
        }
    }

    return bestCols
}

UIScale() {
    w := A_ScreenWidth
    h := A_ScreenHeight

    ; 1366x768 e a base. Mantem a UI legivel em 1024x600 e nao deixa
    ; ficar gigantesca demais em monitor Full HD/4K.
    scale := Min(w / 1366.0, h / 768.0)

    if (scale < 0.68)
        scale := 0.68
    if (scale > 1.15)
        scale := 1.15

    return scale
}

FooterHeight() {
    return Max(50, Round(62 * UIScale()))
}

ClampInt(value, minValue, maxValue) {
    value := Round(value)
    if (value < minValue)
        return minValue
    if (value > maxValue)
        return maxValue
    return value
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
