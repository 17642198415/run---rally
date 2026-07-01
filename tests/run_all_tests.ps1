# Run all Godot unit + UI tests from project root or tests folder.
$ErrorActionPreference = "Continue"
$godot = "D:\develop\Godot_v4.6.3-stable_win64.exe"
$testsDir = $PSScriptRoot
$projectRoot = Split-Path $testsDir -Parent
$unitFiles = Get-ChildItem -Path "$testsDir\unit\test_*.gd" | Sort-Object Name
$uiFiles = @()
$uiDir = Join-Path $testsDir "ui"
if (Test-Path $uiDir) {
    $uiFiles = Get-ChildItem -Path "$uiDir\test_*.gd" | Sort-Object Name
}
$testFiles = @($unitFiles) + @($uiFiles)

if (-not (Test-Path $godot)) {
    Write-Error "Godot not found at $godot"
}

# Register global class_name scripts (MenuStyle, RunState) for headless scene tests.
$importMarker = Join-Path $projectRoot ".godot\global_script_class_cache.cfg"
if (-not (Test-Path $importMarker) -or (Get-Content $importMarker -Raw) -match 'list=\[\]') {
    Write-Host "Running Godot import (global class registration)..."
    & $godot --headless --path $projectRoot --import 2>&1 | Out-Null
}

$failed = @()
foreach ($file in $testFiles) {
    $out = & $godot --headless --path $projectRoot --script $file.FullName 2>&1 | Out-String
    $pass = $out -match "PASS: all tests passed"
    if ($pass) {
        Write-Host "[PASS] $($file.Name)"
    } else {
        Write-Host "[FAIL] $($file.Name)"
        Write-Host $out.TrimEnd()
        $failed += $file.Name
    }
}

if ($failed.Count -gt 0) {
    Write-Host ""
    Write-Host "FAILED ($($failed.Count)/$($testFiles.Count)): $($failed -join ', ')"
    exit 1
}

Write-Host ""
Write-Host "ALL $($testFiles.Count) TESTS PASSED"