# PowerShell script to export Carrom Champions for Web (HTML5)
$ErrorActionPreference = "Stop"

$workspaceRoot = Split-Path -Parent $PSScriptRoot
Set-Location $workspaceRoot

$exportDir = Join-Path $workspaceRoot "export\web"
$zipOutput = Join-Path $workspaceRoot "export\CarromChampions_Web.zip"
$godotExe = Join-Path $workspaceRoot "Godot_v4.3-stable_win64_console.exe"

Write-Host "=== Exporting Carrom Champions for Web (HTML5) ===" -ForegroundColor Cyan

if (-not (Test-Path $godotExe)) {
    Write-Error "Godot 4.3 executable not found at $godotExe"
}

if (-not (Test-Path $exportDir)) {
    New-Item -ItemType Directory -Force -Path $exportDir | Out-Null
}

Write-Host "Running Godot headless Web export..." -ForegroundColor Yellow
$exportProcess = Start-Process -FilePath $godotExe -ArgumentList @("--headless", "--export-release", "Web", "$exportDir\index.html") -Wait -PassThru -NoNewWindow

if ($exportProcess.ExitCode -ne 0) {
    Write-Error "Export failed with exit code $($exportProcess.ExitCode)"
}

$requiredFiles = @("index.html", "index.js", "index.wasm", "index.pck")
$missing = @()
foreach ($file in $requiredFiles) {
    $filePath = Join-Path $exportDir $file
    if (-not (Test-Path $filePath)) {
        $missing += $file
    }
}

if ($missing.Count -gt 0) {
    Write-Error "Export finished but missing required files: $($missing -join ', ')"
}

Write-Host "All core Web files exported successfully:" -ForegroundColor Green
Get-ChildItem -Path $exportDir | Select-Object Name, Length | Format-Table -AutoSize

# Package into Web Zip
if (Test-Path $zipOutput) {
    Remove-Item $zipOutput -Force
}

Write-Host "Compressing bundle into $zipOutput..." -ForegroundColor Yellow
Compress-Archive -Path "$exportDir\*" -DestinationPath $zipOutput -Force

$zipItem = Get-Item $zipOutput
Write-Host "=== Web HTML5 Package Ready ===" -ForegroundColor Green
Write-Host "Package Path: $($zipItem.FullName)"
Write-Host "Package Size: $([math]::Round($zipItem.Length / 1MB, 2)) MB"
