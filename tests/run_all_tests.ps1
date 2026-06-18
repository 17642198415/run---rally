# Run all Godot unit tests from project root or tests folder.
$ErrorActionPreference = "Continue"
$godot = "D:\develop\Godot_v4.6.3-stable_win64.exe"
$testsDir = $PSScriptRoot
$projectRoot = Split-Path $testsDir -Parent
$testFiles = Get-ChildItem -Path "$testsDir\unit\test_*.gd" | Sort-Object Name

if (-not (Test-Path $godot)) {
    Write-Error "Godot not found at $godot"
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
