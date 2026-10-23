@echo off
title Push Carrom Champions to GitHub
echo ========================================================
echo   Pushing Carrom Champions to GitHub (ArunvLB)
echo ========================================================
echo.
cd /d "%~dp0"
echo Current Directory: %CD%
echo.
git push -u origin main
echo.
if %ERRORLEVEL% EQU 0 (
    echo [SUCCESS] Code pushed to GitHub successfully!
    echo Visit: https://github.com/ArunvLB/carrom-champions
) else (
    echo [ERROR] Push failed. 
    echo Please make sure the repository 'carrom-champions' is created on:
    echo https://github.com/new?name=carrom-champions
)
echo.
pause
