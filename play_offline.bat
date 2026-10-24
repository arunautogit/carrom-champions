@echo off
title Carrom Champions - Standalone Web Edition
echo ========================================================
echo   Launching Carrom Champions (Zero Dependency Web Game)
echo ========================================================
echo.
echo Opening Carrom Champions in your browser...

set CHROME_EXE="C:\Program Files\Google\Chrome\Application\chrome.exe"
if not exist %CHROME_EXE% set CHROME_EXE="C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"

set TEMP_PROFILE="%TEMP%\carromweb_profile"

if exist %CHROME_EXE% (
    start "" %CHROME_EXE% --allow-file-access-from-files --ignore-gpu-blocklist --enable-webgl --user-data-dir=%TEMP_PROFILE% "file:///%~dp0index.html"
) else (
    start "" "%~dp0index.html"
)
exit
