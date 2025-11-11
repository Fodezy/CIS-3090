# Assignment 2: Substitution Cipher Decryption

## Quick Start

### Building

```bash
make clean
make
```

### Basic Usage

**Encryption:**
```bash
./a2encrypt "your message here"
# Creates ciphertext.txt
```

**Decryption (Serial):**
```bash
./a2decrypt_serial ciphertext.txt american-english
```

**Decryption (Parallel):**
```bash
mpiexec -n 6 ./a2decrypt ciphertext.txt american-english
```

## Testing

### Correctness Tests

```bash
chmod +x test_correctness.sh
./test_correctness.sh
```

### Performance Tests

```bash
chmod +x test_performance.sh
./test_performance.sh
```

**Note**: Performance tests run each configuration 30 times and may take 30-60 minutes.

### Analyze Results

```bash
# Install R packages (first time only)
Rscript -e "install.packages(c('ggplot2', 'dplyr'), repos='https://cran.rstudio.com/')"

# Generate graphs and statistics
Rscript analyze_performance.R
```

## Report

See `REPORT.md` for complete documentation including:
- Correctness analysis
- Performance analysis
- Test procedures
- Results and conclusions

## Files

- `src/` - Source code
- `test_inputs/` - Test case inputs
- `test_correctness.sh` - Correctness testing script
- `test_performance.sh` - Performance testing script
- `analyze_performance.R` - Performance analysis script
- `REPORT.md` - Complete report
- `american-english` - Dictionary file

## Requirements

- GCC compiler
- MPI (for parallel version)
- R (for performance analysis)
- R packages: ggplot2, dplyr

