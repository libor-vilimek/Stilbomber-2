@echo off
setlocal
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\Start-GameWindowed.ps1"
if errorlevel 1 (
    echo.
    echo Stilbomber could not start. See the error above.
    pause
    exit /b 1
)
