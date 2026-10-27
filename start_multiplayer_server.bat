@echo off
title Carrom Champions - Multiplayer WebSocket Server
echo ========================================================
echo   Carrom Champions - 2-4 Player Multiplayer Server
echo ========================================================
echo.
echo Starting WebSocket & Lobby Server on port 3000...
echo.
cd /d "%~dp0server"
node server.js
pause
