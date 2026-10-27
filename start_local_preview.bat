@echo off
title Carrom Champions - Local Web Preview
echo ========================================================
echo   Carrom Champions - Local HTML5 Web Server
echo ========================================================
echo.
echo Starting web server on http://localhost:8000...

:: Check if Chrome exists and launch with GPU blocklist override for GT 740M / Intel 4600
if exist "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe" (
    echo Launching Google Chrome with WebGL2 hardware override...
    start "" "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe" --ignore-gpu-blocklist --enable-webgl --enable-webgl2-compute-context http://localhost:8000
) else if exist "C:\Program Files\Google\Chrome\Application\chrome.exe" (
    echo Launching Google Chrome with WebGL2 hardware override...
    start "" "C:\Program Files\Google\Chrome\Application\chrome.exe" --ignore-gpu-blocklist --enable-webgl --enable-webgl2-compute-context http://localhost:8000
) else if exist "C:\Program Files (x86)\Mozilla Firefox\firefox.exe" (
    echo Launching Mozilla Firefox...
    start "" "C:\Program Files (x86)\Mozilla Firefox\firefox.exe" http://localhost:8000
) else (
    echo Opening default browser...
    start http://localhost:8000
)

echo.
echo Server is running at http://localhost:8000
echo (Keep this window open while playing. Press Ctrl+C to stop.)
echo.
python -m http.server 8000 --directory "%~dp0export\web"
pause
