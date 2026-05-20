@echo off
title GRBL CH32V307 - Rebuild

set PROJECT_ROOT=%~dp0..
for %%I in ("%PROJECT_ROOT%") do set "PROJECT_ROOT=%%~fI"

echo.
echo =============================================================
echo   GRBL CH32V307 - Rebuild (Clean + Build)
echo =============================================================
echo.

:: Clean first
call "%PROJECT_ROOT%\scripts\clean.bat"

:: Then Build
call "%PROJECT_ROOT%\scripts\build.bat"
