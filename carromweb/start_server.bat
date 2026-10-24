@echo off
title Carrom Champions - Local Web Server
echo ========================================================
echo   Carrom Champions - Standalone Web Server
echo ========================================================
echo.
echo Starting web server on http://localhost:8080...

if exist "C:\Program Files\Google\Chrome\Application\chrome.exe" (
    start "" "C:\Program Files\Google\Chrome\Application\chrome.exe" --ignore-gpu-blocklist --enable-webgl http://localhost:8080
) else if exist "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe" (
    start "" "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe" --ignore-gpu-blocklist --enable-webgl http://localhost:8080
) else (
    start http://localhost:8080
)

echo Server running at http://localhost:8080
echo (Press Ctrl+C to stop the server)
echo.
python -m http.server 8080 --directory "%~dp0."
pause
