@echo off
title Carrom Champions - Offline Web (No Backend Server)
echo ========================================================
echo   Launching Carrom Champions Directly (No Backend Server)
echo ========================================================
echo.
echo Opening game in your browser with ZERO backend server running...

set CHROME_EXE="C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"
if not exist %CHROME_EXE% set CHROME_EXE="C:\Program Files\Google\Chrome\Application\chrome.exe"

set TEMP_PROFILE="%TEMP%\carrom_offline_profile"

start "" %CHROME_EXE% --allow-file-access-from-files --ignore-gpu-blocklist --enable-webgl --user-data-dir=%TEMP_PROFILE% "file:///%~dp0export/web/index.html"
exit
