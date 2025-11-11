# Testing Instructions for A2

## Overview

This document provides step-by-step instructions for running correctness and performance tests.

## Prerequisites

1. **Build all programs:**
   ```bash
   make clean
   make
   ```

2. **Make scripts executable (Linux/WSL):**
   ```bash
   chmod +x test_correctness.sh
   chmod +x test_performance.sh
   ```

3. **Install R and required packages (for analysis):**
   ```bash
   # Ubuntu/Debian
   sudo apt-get install r-base
   
   # macOS
   brew install r
   
   # Install R packages
   Rscript -e "install.packages(c('ggplot2', 'dplyr'), repos='https://cran.rstudio.com/')"
   ```

## Correctness Testing

### Purpose
Verify that serial and parallel versions produce identical results.

### Running Tests

```bash
./test_correctness.sh
```

### What It Tests

1. **Serial vs Parallel (6 processes)**: Ensures both versions find the same valid decryptions
2. **Consistency (1 vs 6 processes)**: Ensures parallel version produces same results regardless of process count
3. **Multiple test cases**: Tests with 3, 4, and 5 unique characters

### Expected Output

```
==========================================
A2 Decryption Correctness Tests
==========================================

Testing: 3 unique characters
Input file: test_inputs/test_3chars.txt
Running serial version...
Running parallel version (6 processes)...
PASSED: Serial and parallel outputs match
Results found:
  - jew pit
  - jew tip
  - pit jew
  - tip jew

...

Test Summary
==========================================
Passed: 3
Failed: 0

All tests passed!
```

## Performance Testing

### Purpose
Collect timing data for 30 runs of each configuration to analyze performance and speedup.

### Running Tests

```bash
./test_performance.sh
```

**Warning**: This will take 30-60 minutes as it runs each test 30 times.

### What It Tests

For each input size (3, 4, 5, 6, 7 unique characters):
- Serial version
- Parallel version with 1 process
- Parallel version with N processes (N = number of unique chars)
- Parallel version with 6 processes (when applicable)

### Output

Results are saved as CSV files in `performance_results/`:
- `serial_3chars.csv`
- `parallel_1proc_3chars.csv`
- `parallel_3proc_3chars.csv`
- `parallel_6proc_3chars.csv`
- (and so on for 4, 5, 6, 7 chars)

Each CSV contains:
```csv
run,time
1,0.123
2,0.125
3,0.122
...
```

## Performance Analysis

### Generating Graphs and Statistics

```bash
Rscript analyze_performance.R
```

### Output

1. **Graphs** (in `performance_plots/`):
   - `execution_time_comparison.png` - Mean execution time vs. number of unique characters
   - `speedup_comparison.png` - Speedup achieved by parallel version
   - `distribution_3chars.png` - Execution time distribution for 3-character inputs
   - `boxplot_all_configs.png` - Box plots showing distributions across all configurations

2. **Statistics** (in `performance_results/`):
   - `statistics_summary.csv` - Mean, median, SD, min, max, quartiles for each configuration

## Manual Testing

### Test a Single Case

```bash
# 1. Encrypt test input
./a2encrypt "$(cat test_inputs/test_3chars.txt)"

# 2. Decrypt with serial
./a2decrypt_serial ciphertext.txt american-english

# 3. Decrypt with parallel (1 process)
mpiexec -n 1 ./a2decrypt ciphertext.txt american-english

# 4. Decrypt with parallel (6 processes)
mpiexec -n 6 ./a2decrypt ciphertext.txt american-english
```

### Verify Results Match

The outputs should contain the same set of valid decryptions (order may differ).

## Understanding Results

### Correctness
- All tests should **PASS**
- Serial and parallel outputs should be **identical**
- Results should be **consistent** across different process counts

### Performance
- **Speedup** = Serial Time / Parallel Time
- Speedup > 1 means parallel is faster
- Optimal speedup when processes = unique characters
- Execution time grows **factorially** with unique characters

### Performance Limits
- **3-4 chars**: Very fast (< 1 second)
- **5 chars**: Fast (1-10 seconds)
- **6 chars**: Moderate (10-60 seconds)
- **7 chars**: Slow (1-5 minutes)
- **8+ chars**: Too slow (> 5 minutes) - impractical

## Troubleshooting

### Scripts not executable
```bash
chmod +x test_correctness.sh test_performance.sh
```

### MPI not found
```bash
# Install MPI
# Ubuntu/Debian
sudo apt-get install libopenmpi-dev openmpi-bin

# macOS
brew install open-mpi
```

### R packages missing
```bash
Rscript -e "install.packages(c('ggplot2', 'dplyr'), repos='https://cran.rstudio.com/')"
```

### Tests taking too long
- Start with smaller inputs (3-4 chars)
- Reduce NUM_RUNS in test_performance.sh (default: 30)
- Skip larger inputs (7+ chars) when prompted

## Report Generation

After running all tests, the data in `performance_results/` and `performance_plots/` can be used to complete the report sections:

1. **Correctness Analysis**: Use test_correctness.sh output
2. **Performance Analysis**: Use CSV files and graphs from analysis
3. **Statistics**: Use statistics_summary.csv
4. **Graphs**: Include PNG files from performance_plots/

See `REPORT.md` for the complete report template.

