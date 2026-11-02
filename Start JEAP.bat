@echo off
title Start JEAP
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\Start-JEAP.ps1"
if errorlevel 1 pause
