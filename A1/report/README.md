# General Info
Names: Alex Daniel and Eric Fode
Date: October 15, 2025
Purpose: Computes Pi, and showcases the differences in thread iterations.

# Compile and Run

## Compile options:
- Compile All: `make` 
  - Will compile both A1.c (parallel pi computation program) & baseLinePi.c (serial pi computation)
  - Object files made are: A1 & baseLinePi

- Compile Just A1: `make A1`
  - Targets only A1.c and creates object file A1 

- Compile Just baseLinePi: `make baseLinePi`
  - Targets only baseLinePi.c and creates object file baseLinePi

## Run options
- Run A1: 
  - Verbose logging set: `./A1 inputs/sample.txt true`
  - Verbose logging off: `./A1 inputs/sample.txt false`
- Memory Leak and DRD check:
  - Memory Check: `valgrind --leak-check=full ./A1 inputs/sample.txt true`
  - DRD Check: `valgrind --tool=drd ./A1 inputs/sample.txt true`

- Run baseLinePi:
  - `./baseLinePi 500000`

- Clean:
  - `make clean`
<!-- 
### Notes
- Set some variables to long long to ensure iteration counts don't overflow -->

## Running Tests 
- Setting up shell scripts as executable:
  - `chmod +x tests/run_tests.sh`

- Running Tests:
  - `./tests/run_tests.sh`
  - This script will either build A1 fresh or clean and rebuild to ensure object file exists
  - Logs for this test file will be redirected from the Terminal to the file: `A1/tests/test_results.log`
