@echo off
title Modo Aluno - Servidor
cd /d "%~dp0"

rem Mantem o config do servidor igual ao config principal do repo.
copy /Y "..\config.ini" "config.ini" >nul

python server.py
if errorlevel 1 (
    echo.
    echo Nao consegui iniciar com "python".
    echo Tentando com "py"...
    py server.py
)
pause
