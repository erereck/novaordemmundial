BuildUI() {
    global UI, UI_VISIBLE, PAGE, CFG, EXTERNAL_ACTIVE, ASSETDIR

    if IsObject(UI) {
        try {
            UI.Destroy()
        } catch {
        }
    }

    title := IniRead(CFG, "General", "Title", "Modo Aluno")
    w := A_ScreenWidth
    h := A_ScreenHeight
    scale := UIScale()

    ; Coordenadas em pixels reais: o Windows nao pode inflar a interface
    ; quando o notebook estiver em escala 125% ou 150%.
    UI := Gui("+AlwaysOnTop -Caption +ToolWindow -DPIScale", title)
    UI.BackColor := "0B1119"
    UI.MarginX := 0
    UI.MarginY := 0

    ; Wallpaper.
    wallpaperFile := IniRead(CFG, "General", "WallpaperFile", "")
    if (wallpaperFile != "") {
        wallpaperPath := ASSETDIR "\" wallpaperFile
        if FileExist(wallpaperPath) {
            try {
                pic := UI.AddPicture("x0 y0 w" w " h" h, wallpaperPath)
            } catch {
            }
        }
    }

    headerH := HeaderHeight()
    footerH := FooterHeight()
    accentH := Max(2, Round(3 * scale))

    ; Faixas escuras deixam texto e controles legiveis mesmo com wallpapers
    ; diferentes. Uma linha azul fina vira a identidade visual do launcher.
    UI.AddText("x0 y0 w" w " h" headerH " Background09111B", " ")
    UI.AddText("x0 y" (headerH - accentH) " w" w " h" accentH " Background2F80ED", " ")

    UI.AddText("x0 y" (h - footerH) " w" w " h" footerH " Background09111B", " ")
    UI.AddText("x0 y" (h - footerH) " w" w " h" accentH " Background2F80ED", " ")

    padX := Max(18, Round(34 * scale))
    titleY := Max(8, Round(13 * scale))
    titleFont := ClampInt(Round(25 * scale), 16, 29)
    subtitleFont := ClampInt(Round(10 * scale), 8, 12)

    if (PAGE = "games") {
        pageTitle := "JOGOS"
        pageSubtitle := "Escolha um jogo  •  F1 ou ESC para voltar"
    } else {
        pageTitle := title
        pageSubtitle := IniRead(CFG, "General", "Subtitle", "Escolha uma atividade")
    }

    titleCtrl := UI.AddText("x" padX " y" titleY " w" (w - padX * 2) " h" Max(28, Round(36 * scale)) " cFFFFFF BackgroundTrans", pageTitle)
    titleCtrl.SetFont("s" titleFont " Bold cFFFFFF", "Segoe UI")

    subtitleY := titleY + Max(30, Round(37 * scale))
    subtitleCtrl := UI.AddText("x" padX " y" subtitleY " w" (w - padX * 2) " h" Max(18, Round(22 * scale)) " cB8C5D8 BackgroundTrans", pageSubtitle)
    subtitleCtrl.SetFont("s" subtitleFont " cB8C5D8", "Segoe UI")

    gridTop := headerH + Max(8, Round(12 * scale))

    if (PAGE = "games") {
        AddGrid(ReadItems("Game"), gridTop)
        AddFooterAction("←  VOLTAR", Max(14, Round(22 * scale)), h - footerH, Max(120, Round(155 * scale)), footerH, (*) => ShowHome())
    } else {
        items := ReadItems("Home")

        if (IniRead(CFG, "Special", "Enabled", "0") = "1") {
            items.InsertAt(1, Map(
                "Name", IniRead(CFG, "Special", "Name", "FAZER PROVA"),
                "Type", IniRead(CFG, "Special", "Type", "web"),
                "Target", IniRead(CFG, "Special", "Target", "https://example.com/prova"),
                "Protected", IniRead(CFG, "Special", "Protected", "0"),
                "IconFile", IniRead(CFG, "Special", "IconFile", ""),
                "IconGlyph", ""
            ))
        }

        if (IniRead(CFG, "General", "GamesEnabled", "1") = "1") {
            items.Push(Map(
                "Name", "JOGOS",
                "Type", "page",
                "Target", "games",
                "Protected", "0",
                "IconFile", "",
                "IconGlyph", "🎮"
            ))
        }

        AddGrid(items, gridTop)
    }

    ; Rodape discreto.
    ver := IniRead(CFG, "General", "Version", "0")
    versionCtrl := UI.AddText("x" padX " y" (h - footerH + accentH + 5) " w250 h18 c7F94AD BackgroundTrans", "MODO ALUNO  •  config v" ver)
    versionCtrl.SetFont("s" ClampInt(Round(8 * scale), 7, 9) " Bold c7F94AD", "Segoe UI")

    exitW := Max(150, Round(185 * scale))
    AddFooterAction("🔒  PROFESSOR / SAIR", w - exitW - Max(14, Round(22 * scale)), h - footerH, exitW, footerH, (*) => AskExit())

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

    sideMargin := Max(14, Round(38 * scale))
    gapX := Max(7, Round(12 * scale))
    gapY := Max(7, Round(12 * scale))
    availableW := w - sideMargin * 2
    availableH := h - topY - footerH - Max(7, Round(10 * scale))

    cols := ChooseColumnCount(items.Length, availableW, availableH, gapX, gapY)
    rows := Ceil(items.Length / cols)

    tileW := Floor((availableW - gapX * (cols - 1)) / cols)
    tileH := Floor((availableH - gapY * (rows - 1)) / rows)

    totalW := cols * tileW + (cols - 1) * gapX
    startX := Floor((w - totalW) / 2)

    borderPx := Max(1, Round(1 * scale))
    labelH := ClampInt(Round(tileH * 0.24), 24, Max(26, Round(38 * scale)))
    labelFont := ClampInt(Round(11 * scale), 8, 12)

    iconSpaceH := tileH - labelH - Max(8, Round(12 * scale))
    iconSize := ClampInt(Min(iconSpaceH, tileW - Max(18, Round(26 * scale)), Round(86 * scale)), 24, 96)
    showIcons := tileH >= 62 && iconSize >= 25

    for index, item in items {
        row := Floor((index - 1) / cols)
        col := Mod(index - 1, cols)
        x := startX + col * (tileW + gapX)
        y := topY + row * (tileH + gapY)

        outerColor := "33475F"
        innerColor := "101823"

        if (item["Protected"] = "1") {
            outerColor := "816829"
            innerColor := "1D1A12"
        } else if (item["Type"] = "page") {
            outerColor := "2F80ED"
            innerColor := "102238"
        } else if (item["Name"] = "FAZER PROVA") {
            outerColor := "3B91FF"
            innerColor := "0E2946"
        }

        outer := UI.AddText("x" x " y" y " w" tileW " h" tileH " Background" outerColor, " ")
        inner := UI.AddText("x" (x + borderPx) " y" (y + borderPx) " w" (tileW - borderPx * 2) " h" (tileH - borderPx * 2) " Background" innerColor, " ")

        outer.OnEvent("Click", RunItem.Bind(item))
        inner.OnEvent("Click", RunItem.Bind(item))

        iconFile := item.Has("IconFile") ? item["IconFile"] : ""
        iconGlyph := item.Has("IconGlyph") ? item["IconGlyph"] : ""
        iconPath := iconFile != "" ? ASSETDIR "\" iconFile : ""
        hasIcon := showIcons && iconPath != "" && FileExist(iconPath)

        if hasIcon {
            iconX := x + Floor((tileW - iconSize) / 2)
            iconY := y + Max(6, Floor((tileH - labelH - iconSize) / 2))

            try {
                icon := UI.AddPicture("x" iconX " y" iconY " w" iconSize " h" iconSize " BackgroundTrans", iconPath)
                icon.OnEvent("Click", RunItem.Bind(item))
            } catch {
                hasIcon := false
            }
        }

        if !hasIcon {
            if (iconGlyph = "")
                iconGlyph := FallbackGlyph(item["Name"])

            glyphH := Max(28, tileH - labelH - Max(8, Round(10 * scale)))
            glyph := UI.AddText("x" (x + 4) " y" (y + 4) " w" (tileW - 8) " h" glyphH " Center 0x200 BackgroundTrans cFFFFFF", iconGlyph)
            glyph.SetFont("s" ClampInt(Round(34 * scale), 18, 42) " cFFFFFF", "Segoe UI Emoji")
            glyph.OnEvent("Click", RunItem.Bind(item))
        }

        label := item["Name"]
        if (item["Protected"] = "1")
            label .= "  🔒"

        labelY := y + tileH - labelH - Max(2, Round(3 * scale))
        labelCtrl := UI.AddText("x" (x + 5) " y" labelY " w" (tileW - 10) " h" labelH " Center 0x200 BackgroundTrans cFFFFFF", label)
        labelCtrl.SetFont("s" labelFont " Bold cFFFFFF", "Segoe UI")
        labelCtrl.OnEvent("Click", RunItem.Bind(item))
    }
}

AddFooterAction(text, x, footerY, width, footerH, callback) {
    global UI

    scale := UIScale()
    h := Max(30, Round(36 * scale))
    y := footerY + Floor((footerH - h) / 2)

    outer := UI.AddText("x" x " y" y " w" width " h" h " Background32475F", " ")
    inner := UI.AddText("x" (x + 1) " y" (y + 1) " w" (width - 2) " h" (h - 2) " Background101823", " ")
    label := UI.AddText("x" (x + 4) " y" (y + 2) " w" (width - 8) " h" (h - 4) " Center 0x200 BackgroundTrans cDCE8F6", text)
    label.SetFont("s" ClampInt(Round(9 * scale), 8, 11) " Bold cDCE8F6", "Segoe UI")

    outer.OnEvent("Click", callback)
    inner.OnEvent("Click", callback)
    label.OnEvent("Click", callback)
}

FallbackGlyph(name) {
    if (name = "")
        return "•"

    if (name = "JOGOS")
        return "🎮"

    return StrUpper(SubStr(name, 1, 1))
}

ChooseColumnCount(itemCount, availableW, availableH, gapX, gapY) {
    if (itemCount <= 0)
        return 1

    maxCols := Min(itemCount, 6)
    minTileW := 128
    minTileH := 76

    ; Primeiro procura o maior numero de colunas que ainda mantenha cada card
    ; confortavel. Isso reduz as linhas em telas baixas.
    Loop maxCols {
        cols := maxCols - A_Index + 1
        rows := Ceil(itemCount / cols)
        tileW := Floor((availableW - gapX * (cols - 1)) / cols)
        tileH := Floor((availableH - gapY * (rows - 1)) / rows)

        if (tileW >= minTileW && tileH >= minTileH)
            return cols
    }

    ; Em resolucao extrema, escolhe a grade que produz o melhor card possivel.
    bestCols := 1
    bestScore := -1

    Loop maxCols {
        cols := A_Index
        rows := Ceil(itemCount / cols)
        tileW := Floor((availableW - gapX * (cols - 1)) / cols)
        tileH := Floor((availableH - gapY * (rows - 1)) / rows)

        if (tileW <= 0 || tileH <= 0)
            continue

        score := Min(tileW / 128.0, tileH / 76.0)
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

    ; 1366x768 e a referencia; 1024x600 continua sendo utilizavel.
    scale := Min(w / 1366.0, h / 768.0)

    if (scale < 0.66)
        scale := 0.66
    if (scale > 1.15)
        scale := 1.15

    return scale
}

HeaderHeight() {
    return Max(66, Round(78 * UIScale()))
}

FooterHeight() {
    return Max(50, Round(58 * UIScale()))
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
            "IconFile", IniRead(CFG, sec, "IconFile", ""),
            "IconGlyph", IniRead(CFG, sec, "IconGlyph", "")
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
        "IconFile", IniRead(CFG, "Special", "IconFile", ""),
        "IconGlyph", ""
    ))
}
