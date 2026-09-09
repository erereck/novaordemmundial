#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent

SetWorkingDir(A_ScriptDir)

SETTINGS := A_ScriptDir "\settings.ini"
LOCALCFG := A_ScriptDir "\config.ini"
CACHEDIR := A_ScriptDir "\cache"
CACHECFG := CACHEDIR "\config.ini"
ASSETDIR := CACHEDIR "\assets"

global CFG := LOCALCFG
global CFG_VERSION := "0"
global PAGE := "home"
global UI := 0
global UI_VISIBLE := false
global EXTERNAL_ACTIVE := false
global EXTERNAL_PID := 0
global EXTERNAL_HWND := 0
global EXTERNAL_TITLE := ""
global EXTERNAL_STARTED := 0
global WEB_GUARD_ACTIVE := false
global WEB_GUARD_MISSES := 0
global STUDENT_WINDOWS := Map()
global STUDENT_PIDS := Map()
global LAST_STUDENT_HWND := 0

#Include "src\Sync.ahk"
#Include "src\UI.ahk"
#Include "src\WebGuard.ahk"
#Include "src\Apps.ahk"
#Include "src\Security.ahk"
#Include "src\Windows.ahk"
#Include "src\Updater.ahk"

DirCreate(CACHEDIR)
DirCreate(ASSETDIR)
OnExit(RestoreWindows)

; A partir da v5 o programa se atualiza sozinho pelo GitHub.
if CheckForProgramUpdate()
    ExitApp()

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
#^d::Return

; Alt+Tab foi liberado na v5.
^!+F12::AskExit()
^!+u::OpenStudentChromeSetup()
^!+q::CloseAllOutsideLauncher()
F1::ShowHome()

#HotIf LauncherActive()
g::OpenHomeNamed("Google")
t::OpenHomeNamed("Tux Paint")
p::OpenHomeNamed("Poki")
l::OpenHomeNamed("Typing Land")
c::OpenHomeNamed("Canva")
o::OpenHomeNamed("PowerPoint")
F8::ShowGames()
F6::OpenSpecial()
Esc::GoBack()
!F4::AskExit()
#HotIf

HideTaskbar()
SyncNow()
ChooseConfig()
CFG_VERSION := IniRead(CFG, "General", "Version", "0")
SyncAssets(false)
BuildUI()

seconds := Integer(IniRead(SETTINGS, "Sync", "SyncSeconds", "10"))
if (seconds < 5)
    seconds := 5
SetTimer(CheckUpdate, seconds * 1000)

; Procura uma nova versao a cada 15 minutos, mas so instala quando nao ha
; atividade externa aberta.
SetTimer(AutoUpdateTick, 900000)
