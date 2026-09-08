@echo off
title Modo Aluno - Servidor
cd /d "%~dp0"
python server.py
if errorlevel 1 (
    echo.
    echo Nao consegui iniciar com "python".
    echo Tentando com "py"...
    py server.py
)
pause
