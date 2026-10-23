@echo off
title Carrom Champions - Local Web Preview
echo ========================================================
echo   Carrom Champions - Local HTML5 Web Server
echo ========================================================
echo.
echo Opening http://localhost:8000 in your browser...
start http://localhost:8000
echo.
echo Server running on http://localhost:8000
echo (Press Ctrl+C to stop the server)
echo.
python -m http.server 8000 --directory "%~dp0export\web"
pause
