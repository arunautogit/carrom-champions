@echo off
title Build Carrom Champions Android APK
echo ========================================================
echo   Building Carrom Champions Android APK
echo ========================================================
echo.

set GRADLE_BIN=C:\Users\dmin\.gradle\wrapper\dists\gradle-8.11.1-bin\bpt9gzteqjrbo1mjrsomdt32c\gradle-8.11.1\bin\gradle.bat

if not exist "%GRADLE_BIN%" (
    echo [ERROR] Gradle executable not found at:
    echo %GRADLE_BIN%
    pause
    exit /b 1
)

echo [1/3] Syncing latest HTML5 web assets to Android build...
copy /Y "%~dp0index.html" "%~dp0android_build\app\src\main\assets\" >nul
copy /Y "%~dp0crackers_data.json" "%~dp0android_build\app\src\main\assets\" >nul
copy /Y "%~dp0cracker_enhancement_notes.json" "%~dp0android_build\app\src\main\assets\" >nul
copy /Y "%~dp0index.png" "%~dp0android_build\app\src\main\assets\" >nul
copy /Y "%~dp0index.icon.png" "%~dp0android_build\app\src\main\assets\" >nul
copy /Y "%~dp0index.apple-touch-icon.png" "%~dp0android_build\app\src\main\assets\" >nul
copy /Y "%~dp0index.audio.worklet.js" "%~dp0android_build\app\src\main\assets\" >nul

echo [2/3] Compiling Android APK with Gradle...
cd /d "%~dp0android_build"
call "%GRADLE_BIN%" assembleDebug

if %ERRORLEVEL% EQU 0 (
    echo.
    echo [3/3] Copying APK to root folder...
    copy /Y "%~dp0android_build\app\build\outputs\apk\debug\app-debug.apk" "%~dp0CarromChampions.apk" >nul
    echo ========================================================
    echo   [SUCCESS] APK BUILT SUCCESSFULLY!
    echo   File: F:\carromweb\CarromChampions.apk
    echo ========================================================
) else (
    echo.
    echo [ERROR] APK build failed. Check error messages above.
)

pause
