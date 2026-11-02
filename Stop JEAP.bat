@echo off
title Stop JEAP
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\Stop-JEAP.ps1"
pause
