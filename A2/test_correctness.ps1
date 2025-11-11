# Correctness Testing Script for A2 Decryption (PowerShell Version)
# This script tests both serial and parallel versions to verify correctness

Write-Host "=========================================="
Write-Host "A2 Decryption Correctness Tests"
Write-Host "=========================================="
Write-Host ""

$DICT = "american-english"
$TEST_DIR = "test_inputs"
$PASSED = 0
$FAILED = 0

# Function to test a single input
function Test-Input {
    param(
        [string]$InputFile,
        [string]$TestName
    )
    
    Write-Host "Testing: $TestName"
    Write-Host "Input file: $InputFile"
    
    # Encrypt the input
    $inputText = Get-Content $InputFile -Raw
    $encryptExe = if (Test-Path "a2encrypt.exe") { ".\a2encrypt.exe" } else { ".\a2encrypt" }
    
    # Check if encryption executable is Linux binary
    $isLinuxEncrypt = Test-IsLinuxBinary $encryptExe
    
    if ($isLinuxEncrypt) {
        $wslExe = ConvertTo-WSLPath $encryptExe
        $result = wsl $wslExe $inputText.Trim() 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Host -ForegroundColor Red "FAILED: Encryption failed"
            $script:FAILED++
            return $false
        }
    } else {
        try {
            & $encryptExe $inputText.Trim() 2>&1 | Out-Null
            if ($LASTEXITCODE -ne 0) {
                Write-Host -ForegroundColor Red "FAILED: Encryption failed"
                $script:FAILED++
                return $false
            }
        } catch {
            Write-Host -ForegroundColor Red "FAILED: Encryption failed: $_"
            $script:FAILED++
            return $false
        }
    }
    
    # Get serial results
    Write-Host "Running serial version..."
    $decryptSerialExe = if (Test-Path "a2decrypt_serial.exe") { ".\a2decrypt_serial.exe" } else { ".\a2decrypt_serial" }
    $isLinuxSerial = Test-IsLinuxBinary $decryptSerialExe
    
    if ($isLinuxSerial) {
        $wslExe = ConvertTo-WSLPath $decryptSerialExe
        $wslCipher = ConvertTo-WSLPath "ciphertext.txt"
        $wslDict = ConvertTo-WSLPath $DICT
        $serialOutput = wsl $wslExe $wslCipher $wslDict 2>&1 | Select-String -Pattern "^serial:" | ForEach-Object { $_.Line }
    } else {
        $serialOutput = & $decryptSerialExe ciphertext.txt $DICT 2>&1 | Select-String -Pattern "^serial:" | ForEach-Object { $_.Line }
    }
    $SERIAL_OUTPUT = ($serialOutput | Sort-Object) -join "`n"
    
    # Get parallel results (with 6 processes)
    Write-Host "Running parallel version (6 processes)..."
    $decryptExe = if (Test-Path "a2decrypt.exe") { ".\a2decrypt.exe" } else { ".\a2decrypt" }
    $isLinuxDecrypt = Test-IsLinuxBinary $decryptExe
    
    if ($isLinuxDecrypt) {
        $wslExe = ConvertTo-WSLPath $decryptExe
        $wslCipher = ConvertTo-WSLPath "ciphertext.txt"
        $wslDict = ConvertTo-WSLPath $DICT
        $parallelOutput = wsl mpiexec -n 6 $wslExe $wslCipher $wslDict 2>&1 | Select-String -Pattern "^rank" | ForEach-Object { $_.Line -replace "rank \d+: ", "" }
    } else {
        $parallelOutput = mpiexec -n 6 $decryptExe ciphertext.txt $DICT 2>&1 | Select-String -Pattern "^rank" | ForEach-Object { $_.Line -replace "rank \d+: ", "" }
    }
    $PARALLEL_OUTPUT = ($parallelOutput | Sort-Object -Unique) -join "`n"
    
    # Compare results
    if ($SERIAL_OUTPUT -eq $PARALLEL_OUTPUT) {
        Write-Host -ForegroundColor Green "PASSED: Serial and parallel outputs match"
        Write-Host "Results found:"
        $serialOutput | ForEach-Object { Write-Host "  - $($_.Replace('serial: ', ''))" }
        $script:PASSED++
        return $true
    } else {
        Write-Host -ForegroundColor Red "FAILED: Outputs do not match"
        Write-Host "Serial output:"
        Write-Host $SERIAL_OUTPUT
        Write-Host "Parallel output:"
        Write-Host $PARALLEL_OUTPUT
        $script:FAILED++
        return $false
    }
    Write-Host ""
}

# Test with 1 process vs 6 processes
function Test-Consistency {
    param(
        [string]$InputFile,
        [string]$TestName
    )
    
    Write-Host "Testing consistency: $TestName"
    Write-Host "Input file: $InputFile"
    
    # Encrypt the input
    $inputText = Get-Content $InputFile -Raw
    $encryptExe = if (Test-Path "a2encrypt.exe") { ".\a2encrypt.exe" } else { ".\a2encrypt" }
    $isLinuxEncrypt = Test-IsLinuxBinary $encryptExe
    
    if ($isLinuxEncrypt) {
        $wslExe = ConvertTo-WSLPath $encryptExe
        wsl $wslExe $inputText.Trim() 2>&1 | Out-Null
    } else {
        & $encryptExe $inputText.Trim() 2>&1 | Out-Null
    }
    
    # Get results with 1 process
    $decryptExe = if (Test-Path "a2decrypt.exe") { ".\a2decrypt.exe" } else { ".\a2decrypt" }
    $isLinuxDecrypt = Test-IsLinuxBinary $decryptExe
    
    if ($isLinuxDecrypt) {
        $wslExe = ConvertTo-WSLPath $decryptExe
        $wslCipher = ConvertTo-WSLPath "ciphertext.txt"
        $wslDict = ConvertTo-WSLPath $DICT
        $output1 = wsl mpiexec -n 1 $wslExe $wslCipher $wslDict 2>&1 | Select-String -Pattern "^rank" | ForEach-Object { $_.Line -replace "rank \d+: ", "" }
        $output6 = wsl mpiexec -n 6 $wslExe $wslCipher $wslDict 2>&1 | Select-String -Pattern "^rank" | ForEach-Object { $_.Line -replace "rank \d+: ", "" }
    } else {
        $output1 = mpiexec -n 1 $decryptExe ciphertext.txt $DICT 2>&1 | Select-String -Pattern "^rank" | ForEach-Object { $_.Line -replace "rank \d+: ", "" }
        $output6 = mpiexec -n 6 $decryptExe ciphertext.txt $DICT 2>&1 | Select-String -Pattern "^rank" | ForEach-Object { $_.Line -replace "rank \d+: ", "" }
    }
    
    $OUTPUT_1 = ($output1 | Sort-Object -Unique) -join "`n"
    $OUTPUT_6 = ($output6 | Sort-Object -Unique) -join "`n"
    
    if ($OUTPUT_1 -eq $OUTPUT_6) {
        Write-Host -ForegroundColor Green "PASSED: 1 process and 6 processes produce same results"
        $script:PASSED++
        return $true
    } else {
        Write-Host -ForegroundColor Red "FAILED: Results differ between 1 and 6 processes"
        Write-Host "1 process output:"
        Write-Host $OUTPUT_1
        Write-Host "6 processes output:"
        Write-Host $OUTPUT_6
        $script:FAILED++
        return $false
    }
    Write-Host ""
}

# Helper functions (same as in test_performance.ps1)
function Test-IsLinuxBinary {
    param([string]$FilePath)
    
    if (-not (Test-Path $FilePath)) { return $false }
    
    try {
        $bytes = [System.IO.File]::ReadAllBytes($FilePath)
        # ELF magic number: 0x7F 0x45 0x4C 0x46
        if ($bytes.Length -ge 4 -and $bytes[0] -eq 0x7F -and $bytes[1] -eq 0x45 -and $bytes[2] -eq 0x4C -and $bytes[3] -eq 0x46) {
            return $true
        }
    } catch {
        return $false
    }
    return $false
}

function ConvertTo-WSLPath {
    param([string]$WindowsPath)
    
    # Get absolute path
    if (-not [System.IO.Path]::IsPathRooted($WindowsPath)) {
        $WindowsPath = Join-Path (Get-Location).Path $WindowsPath
    }
    
    # Convert to WSL path format
    $wslPath = $WindowsPath -replace '\\', '/' -replace '^([A-Z]):', '/mnt/$1' -replace ':', ''
    $wslPath = $wslPath.ToLower()
    
    return $wslPath
}

# Run tests
Write-Host "Test 1: 3 unique characters"
Test-Input -InputFile "$TEST_DIR\test_3chars.txt" -TestName "3 unique characters"

Write-Host "Test 2: 4 unique characters"
Test-Input -InputFile "$TEST_DIR\test_4chars.txt" -TestName "4 unique characters"

Write-Host "Test 3: Consistency check (1 vs 6 processes)"
Test-Consistency -InputFile "$TEST_DIR\test_3chars.txt" -TestName "Process count consistency"

Write-Host "=========================================="
Write-Host "Test Summary"
Write-Host "=========================================="
Write-Host -ForegroundColor Green "Passed: $PASSED"
Write-Host -ForegroundColor Red "Failed: $FAILED"
Write-Host ""

if ($FAILED -eq 0) {
    Write-Host -ForegroundColor Green "All tests passed!"
    exit 0
} else {
    Write-Host -ForegroundColor Red "Some tests failed!"
    exit 1
}

