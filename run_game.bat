@echo off
title Carrom Champions - 2-4 Player Multiplayer Game & Server
color 0e
cls

echo =============================================================================
echo   CARROM CHAMPIONS - 2-4 PLAYER MULTIPLAYER EDITION
echo =============================================================================
echo.
echo [1/3] Checking Node.js environment...

where node >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    color 0c
    echo [ERROR] Node.js is not found in your PATH.
    echo Please install Node.js from https://nodejs.org or run play_offline.bat.
    echo.
    pause
    exit /b 1
)

echo [2/3] Checking server dependencies...
cd /d "%~dp0server"
if not exist "node_modules\ws" (
    echo Installing WebSocket server dependencies...
    call npm install --no-audit --no-fund
)

echo [3/3] Starting Unified Game Server (Frontend + WebSockets)...
echo.
echo =============================================================================
echo   Server is running at:
echo   - Local Computer: http://localhost:3000
echo   - Wi-Fi Devices:  http://192.168.0.107:3000
echo =============================================================================
echo.
echo Opening game in your web browser...

:: Open browser after 1 second
start "" cmd /c "timeout /t 1 /nobreak >nul & start http://localhost:3000"

:: Start the unified server
node server.js

pause
