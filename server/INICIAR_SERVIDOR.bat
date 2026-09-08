@echo off
title Modo Aluno - Servidor
cd /d "%~dp0"

rem Na primeira execucao cria o config do servidor a partir do config principal.
rem Depois disso o painel pode alterar server\config.ini sem perder tudo ao reiniciar.
if not exist "config.ini" copy /Y "..\config.ini" "config.ini" >nul

python server.py
if errorlevel 1 (
    echo.
    echo Nao consegui iniciar com "python".
    echo Tentando com "py"...
    py server.py
)
pause
