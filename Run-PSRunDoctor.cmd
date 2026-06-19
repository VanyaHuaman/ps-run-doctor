@echo off
setlocal

if "%~1"=="" (
    goto gui
)

where pwsh.exe >nul 2>nul
if errorlevel 1 (
    echo PS Run Doctor could not find PowerShell 7 ^(pwsh.exe^) on PATH.
    echo.
    echo Install PowerShell 7, then try again:
    echo   winget install --id Microsoft.PowerShell --source winget
    echo.
    echo If PowerShell 7 is installed, open a new terminal or add pwsh.exe to PATH.
    exit /b 1
)

set "POWERSHELL_UPDATECHECK=Off"
pwsh.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0Invoke-PSRunDoctor.ps1" -ScriptPath "%~1" -SuppressPowerShellUpdateCheck
exit /b %ERRORLEVEL%

:gui
where pwsh.exe >nul 2>nul
if errorlevel 1 (
    echo PS Run Doctor could not find PowerShell 7 ^(pwsh.exe^) on PATH.
    echo.
    echo Install PowerShell 7, then try again:
    echo   winget install --id Microsoft.PowerShell --source winget
    echo.
    echo If PowerShell 7 is installed, open a new terminal or add pwsh.exe to PATH.
    pause
    exit /b 1
)

set "POWERSHELL_UPDATECHECK=Off"
pwsh.exe -STA -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0Show-PSRunDoctor.ps1"
exit /b %ERRORLEVEL%
