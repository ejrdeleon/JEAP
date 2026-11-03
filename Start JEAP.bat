@echo off
title Start JEAP
cd /d "%~dp0"
echo Starting JEAP...
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\Start-JEAP.ps1"
set "ERR=%ERRORLEVEL%"
echo.
if not "%ERR%"=="0" (
  echo Start JEAP did not finish cleanly. Read the messages above.
  pause
  exit /b %ERR%
)
echo You can close this window. JEAP keeps running in the background.
timeout /t 8 /nobreak >nul
