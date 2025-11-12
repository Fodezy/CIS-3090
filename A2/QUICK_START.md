# Quick Start Guide for Testing

## The Problem

You're on Windows PowerShell, but the original scripts were written for bash (Linux). Here's how to fix it:

## Step 1: Verify Everything Works

First, test that your programs work:

```powershell
.\test_simple.ps1
```

This will:
- Check if all executables exist
- Test encryption
- Test decryption (serial and parallel)
- Show you what's working and what's not

## Step 2: Run Performance Tests

Once everything works, run the performance tests to generate CSV files:

```powershell
.\test_performance.ps1
```

**This will take 30-60 minutes** because it runs each test 30 times.

The script will create CSV files in `performance_results\` like:
- `serial_3chars.csv`
- `parallel_1proc_3chars.csv`
- `parallel_3proc_3chars.csv`
- etc.

Each CSV file looks like:
```csv
run,time
1,0.123
2,0.125
3,0.122
...
```

## Step 3: Analyze Results

Once you have CSV files, run the R script:

```powershell
Rscript analyze_performance.R
```

This will:
- Read all the CSV files
- Calculate statistics (mean, median, SD, etc.)
- Generate graphs in `performance_plots\`
- Create `statistics_summary.csv`

## What CSV Files Should Exist?

After running `test_performance.ps1`, you should have:

For 3 characters:
- `serial_3chars.csv`
- `parallel_1proc_3chars.csv`
- `parallel_3proc_3chars.csv`
- `parallel_6proc_3chars.csv`

For 4 characters:
- `serial_4chars.csv`
- `parallel_1proc_4chars.csv`
- `parallel_4proc_4chars.csv`
- `parallel_6proc_4chars.csv`

And so on for 5, 6, (and optionally 7) characters.

## Troubleshooting

### "No CSV files found"
- You need to run `test_performance.ps1` first
- Make sure it completes without errors
- Check that `performance_results\` directory exists and has CSV files

### "Executables not found"
- Run `make` to build the programs
- Check that `a2encrypt`, `a2decrypt_serial`, and `a2decrypt` exist

### "MPI not found"
- You need MPI installed for the parallel version
- On Windows, you might need to use WSL (Windows Subsystem for Linux)

### Script doesn't run
- Make sure you're in PowerShell (not Command Prompt)
- Use `.\test_performance.ps1` (with the `.\` prefix)
- If you get execution policy errors, run: `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`

## Alternative: Use WSL (Windows Subsystem for Linux)

If you have WSL installed, you can use the original bash scripts:

```bash
# In WSL
chmod +x test_performance.sh
./test_performance.sh
```

This might be easier if MPI is already set up in WSL.

