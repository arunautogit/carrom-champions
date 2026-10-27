@echo off
title Push Carrom Champions to GitHub
echo ========================================================
echo   Pushing Carrom Champions to GitHub (arunautogit)
echo ========================================================
echo.
cd /d "%~dp0"
echo Current Directory: %CD%
echo.
git push -u origin main --force
echo.
if %ERRORLEVEL% EQU 0 (
    echo [SUCCESS] Code pushed to GitHub successfully!
    echo Visit: https://github.com/arunautogit/carrom-champions
    echo Live Game URL: https://arunautogit.github.io/carrom-champions/
) else (
    echo [NOTE] If prompted for credentials:
    echo Username: arunautogit
    echo Password: Use your GitHub Personal Access Token (PAT)
)
echo.
pause
