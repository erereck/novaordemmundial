IsTuxPaintWindow(hwnd := 0) {
    if !hwnd
        hwnd := WinActive("A")

    if !hwnd
        return false

    exe := ""
    try exe := StrLower(WinGetProcessName("ahk_id " hwnd))

    return exe = "tuxpaint.exe"
}

HandleTuxPaintCloseClick(*) {
    hwnd := WinActive("A")
    if !IsTuxPaintWindow(hwnd)
        return

    ; Pergunta ao Windows qual parte da janela esta sob o mouse.
    ; HTCLOSE = 20, entao nao dependemos de resolucao, DPI ou tamanho da barra.
    MouseGetPos(&mouseX, &mouseY)
    lParam := ((mouseY & 0xFFFF) << 16) | (mouseX & 0xFFFF)

    hit := 0
    try hit := SendMessage(0x84, 0, lParam, , "ahk_id " hwnd) ; WM_NCHITTEST

    if (hit != 20)
        return

    ForceCloseTuxPaint(hwnd)
}

ForceCloseTuxPaint(hwnd := 0) {
    if !hwnd
        hwnd := WinActive("A")

    if !IsTuxPaintWindow(hwnd)
        return

    pid := 0
    try pid := WinGetPID("ahk_id " hwnd)

    if !pid
        return

    ; Nao envia WM_CLOSE: mata o processo para evitar dialogo de confirmacao,
    ; salvamento ou qualquer outro atraso de encerramento.
    try ProcessClose(pid)
}
