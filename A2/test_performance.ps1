# Performance Testing Script for A2 Decryption (PowerShell Version)
# Runs each test 30 times and collects timing data

Write-Host "=========================================="
Write-Host "A2 Decryption Performance Tests"
Write-Host "=========================================="
Write-Host ""

$DICT = "american-english"
$TEST_DIR = "test_inputs"
$NUM_RUNS = 30 
$OUTPUT_DIR = "performance_results"

# Create output directory
if (-not (Test-Path $OUTPUT_DIR)) {
    New-Item -ItemType Directory -Path $OUTPUT_DIR | Out-Null
}

# Function to check if file is Linux ELF binary
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

# Function to convert Windows path to WSL path
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

# Function to time a single run
function Time-Run {
    param(
        [string]$Executable,
        [string[]]$Arguments
    )
    
    # Check if executable is Linux binary
    $isLinux = Test-IsLinuxBinary $Executable
    
    # Measure execution time
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    try {
        if ($isLinux) {
            # Run through WSL - convert executable path and file arguments
            $wslExe = ConvertTo-WSLPath $Executable
            $wslArgs = @()
            foreach ($arg in $Arguments) {
                # If it's a file that exists, convert path; otherwise use as-is
                if (Test-Path $arg) {
                    $wslArgs += ConvertTo-WSLPath $arg
                } else {
                    $wslArgs += $arg
                }
            }
            $allArgs = @($wslExe) + $wslArgs
            wsl $allArgs 2>&1 | Out-Null
        } else {
            # Run directly
            & $Executable $Arguments 2>&1 | Out-Null
        }
    } catch {
        # Ignore errors for timing purposes - but this might indicate a problem
    }
    
    $stopwatch.Stop()
    
    # Return time in seconds (as decimal)
    return [math]::Round($stopwatch.Elapsed.TotalSeconds, 3)
}

# Function to run performance test
function Run-PerformanceTest {
    param(
        [string]$InputFile,
        [string]$TestName,
        [int]$NumChars
    )
    
    Write-Host "Running performance test: $TestName ($NumChars unique characters)"
    Write-Host "Number of runs: $NUM_RUNS"
    
    # Encrypt the input
    $inputText = Get-Content $InputFile -Raw
    $encryptExe = if (Test-Path "a2encrypt.exe") { ".\a2encrypt.exe" } else { ".\a2encrypt" }
    
    # Check if encryption executable is Linux binary
    $isLinuxEncrypt = Test-IsLinuxBinary $encryptExe
    
    if ($isLinuxEncrypt) {
        # Run through WSL
        $wslExe = ConvertTo-WSLPath $encryptExe
        $wslArgs = $inputText.Trim()
        wsl $wslExe $wslArgs 2>&1 | Out-Null
    } else {
        # Run directly
        & $encryptExe $inputText.Trim() 2>&1 | Out-Null
    }
    
    # Determine executable names with full paths
    $decryptSerialExe = if (Test-Path "a2decrypt_serial.exe") { ".\a2decrypt_serial.exe" } else { ".\a2decrypt_serial" }
    $decryptExe = if (Test-Path "a2decrypt.exe") { ".\a2decrypt.exe" } else { ".\a2decrypt" }
    
    # Test serial version
    Write-Host "  Testing serial version..."
    $SERIAL_FILE = "$OUTPUT_DIR\serial_${NumChars}chars.csv"
    "run,time" | Out-File -FilePath $SERIAL_FILE -Encoding ASCII
    for ($i = 1; $i -le $NUM_RUNS; $i++) {
        $TIME = Time-Run -Executable $decryptSerialExe -Arguments @("ciphertext.txt", $DICT)
        "$i,$TIME" | Out-File -FilePath $SERIAL_FILE -Append -Encoding ASCII
        Write-Host -NoNewline "."
    }
    Write-Host " Done"
    
    # Test parallel version with 1 process
    Write-Host "  Testing parallel version (1 process)..."
    $PARALLEL_1_FILE = "$OUTPUT_DIR\parallel_1proc_${NumChars}chars.csv"
    "run,time" | Out-File -FilePath $PARALLEL_1_FILE -Encoding ASCII
    for ($i = 1; $i -le $NUM_RUNS; $i++) {
        $TIME = Time-Run -Executable "mpiexec" -Arguments @("-n", "1", $decryptExe, "ciphertext.txt", $DICT)
        "$i,$TIME" | Out-File -FilePath $PARALLEL_1_FILE -Append -Encoding ASCII
        Write-Host -NoNewline "."
    }
    Write-Host " Done"
    
    # Test parallel version with optimal processes (equal to num_chars)
    # Commented out for faster testing - uncomment if you need this data
    # if ($NumChars -le 6) {
    #     Write-Host "  Testing parallel version ($NumChars processes)..."
    #     $PARALLEL_N_FILE = "$OUTPUT_DIR\parallel_${NumChars}proc_${NumChars}chars.csv"
    #     "run,time" | Out-File -FilePath $PARALLEL_N_FILE -Encoding ASCII
    #     for ($i = 1; $i -le $NUM_RUNS; $i++) {
    #         $TIME = Time-Run -Executable "mpiexec" -Arguments @("-n", "$NumChars", $decryptExe, "ciphertext.txt", $DICT)
    #         "$i,$TIME" | Out-File -FilePath $PARALLEL_N_FILE -Append -Encoding ASCII
    #         Write-Host -NoNewline "."
    #     }
    #     Write-Host " Done"
    # }
    
    # Test parallel version with 6 processes (only for smaller inputs to save time)
    if ($NumChars -le 4) {
        Write-Host "  Testing parallel version (6 processes)..."
        $PARALLEL_6_FILE = "$OUTPUT_DIR\parallel_6proc_${NumChars}chars.csv"
        "run,time" | Out-File -FilePath $PARALLEL_6_FILE -Encoding ASCII
        for ($i = 1; $i -le $NUM_RUNS; $i++) {
            $TIME = Time-Run -Executable "mpiexec" -Arguments @("-n", "6", $decryptExe, "ciphertext.txt", $DICT)
            "$i,$TIME" | Out-File -FilePath $PARALLEL_6_FILE -Append -Encoding ASCII
            Write-Host -NoNewline "."
        }
        Write-Host " Done"
    }
    
    Write-Host ""
}

# Run performance tests
Write-Host "Starting performance tests..."
Write-Host ""

Run-PerformanceTest -InputFile "$TEST_DIR\test_3chars.txt" -TestName "3 unique characters" -NumChars 3
Run-PerformanceTest -InputFile "$TEST_DIR\test_4chars.txt" -TestName "4 unique characters" -NumChars 4
Run-PerformanceTest -InputFile "$TEST_DIR\test_5chars.txt" -TestName "5 unique characters" -NumChars 5
# Commented out 6 chars test - takes too long even with 5 runs
# Run-PerformanceTest -InputFile "$TEST_DIR\test_6chars.txt" -TestName "6 unique characters" -NumChars 6

# Test larger inputs (commented out - too slow)
# Write-Host "Testing larger inputs (this may take a while)..."
# Write-Host ""

# Test 7 chars (commented out - too slow, exceeds 5 minute limit)
# Write-Host "Testing 7 unique characters (may take several minutes)..."
# $response = Read-Host "Continue? (y/n)"
# if ($response -match "^[Yy]") {
#     Run-PerformanceTest -InputFile "$TEST_DIR\test_7chars.txt" -TestName "7 unique characters" -NumChars 7
# }

Write-Host "=========================================="
Write-Host "Performance tests complete!"
Write-Host "Results saved in: $OUTPUT_DIR\"
Write-Host "=========================================="

