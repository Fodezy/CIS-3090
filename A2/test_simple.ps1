# Simple test script to verify everything works
# This will help debug issues

Write-Host "Testing A2 Decryption Setup"
Write-Host "=========================="
Write-Host ""

# Check if executables exist
Write-Host "Checking executables..."
$executables = @("a2encrypt", "a2encrypt.exe", "a2decrypt_serial", "a2decrypt_serial.exe", "a2decrypt", "a2decrypt.exe")
$found = $false
foreach ($exe in $executables) {
    if (Test-Path $exe) {
        Write-Host "  Found: $exe"
        $found = $true
        break
    }
}
if (-not $found) {
    Write-Host "  ERROR: No executables found! Run 'make' first."
    exit 1
}

# Check if dictionary exists
Write-Host "Checking dictionary..."
if (Test-Path "american-english") {
    Write-Host "  Found: american-english"
} else {
    Write-Host "  ERROR: Dictionary file 'american-english' not found!"
    exit 1
}

# Check test inputs
Write-Host "Checking test inputs..."
if (Test-Path "test_inputs") {
    $testFiles = Get-ChildItem "test_inputs\*.txt"
    Write-Host "  Found $($testFiles.Count) test file(s)"
    foreach ($file in $testFiles) {
        Write-Host "    - $($file.Name)"
    }
} else {
    Write-Host "  ERROR: test_inputs directory not found!"
    exit 1
}

# Test encryption
Write-Host ""
Write-Host "Testing encryption..."
$testInput = Get-Content "test_inputs\test_3chars.txt" -Raw
Write-Host "  Input: $($testInput.Trim())"

# Determine which executable to use
$encryptExe = if (Test-Path "a2encrypt.exe") { "a2encrypt.exe" } else { "a2encrypt" }
$decryptSerialExe = if (Test-Path "a2decrypt_serial.exe") { "a2decrypt_serial.exe" } else { "a2decrypt_serial" }
$decryptExe = if (Test-Path "a2decrypt.exe") { "a2decrypt.exe" } else { "a2decrypt" }

try {
    & ".\$encryptExe" $testInput.Trim() 2>&1 | Out-Null
    if (Test-Path "ciphertext.txt") {
        Write-Host "  SUCCESS: ciphertext.txt created"
        $cipher = Get-Content "ciphertext.txt" -Raw
        Write-Host "  Ciphertext: $($cipher.Trim())"
    } else {
        Write-Host "  ERROR: ciphertext.txt not created!"
        exit 1
    }
} catch {
    Write-Host "  ERROR: Encryption failed: $_"
    exit 1
}

# Test serial decryption
Write-Host ""
Write-Host "Testing serial decryption..."
try {
    $output = & ".\$decryptSerialExe" ciphertext.txt american-english 2>&1
    Write-Host "  Output:"
    $output | ForEach-Object { Write-Host "    $_" }
} catch {
    Write-Host "  ERROR: Serial decryption failed: $_"
    exit 1
}

# Test parallel decryption (1 process)
Write-Host ""
Write-Host "Testing parallel decryption (1 process)..."
try {
    $output = & mpiexec -n 1 $decryptExe ciphertext.txt american-english 2>&1
    Write-Host "  Output:"
    $output | ForEach-Object { Write-Host "    $_" }
} catch {
    Write-Host "  ERROR: Parallel decryption failed: $_"
    exit 1
}

Write-Host ""
Write-Host "=========================="
Write-Host "All basic tests passed!"
Write-Host "=========================="

