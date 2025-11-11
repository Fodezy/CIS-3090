#!/bin/bash

# Correctness Testing Script for A2 Decryption
# This script tests both serial and parallel versions to verify correctness

echo "=========================================="
echo "A2 Decryption Correctness Tests"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

DICT="american-english"
TEST_DIR="test_inputs"
PASSED=0
FAILED=0

# Function to test a single input
test_input() {
    local input_file=$1
    local test_name=$2
    
    echo "Testing: $test_name"
    echo "Input file: $input_file"
    
    # Encrypt the input
    if ! ./a2encrypt "$(cat $input_file)" > /dev/null 2>&1; then
        echo -e "${RED}FAILED: Encryption failed${NC}"
        ((FAILED++))
        return 1
    fi
    
    # Get serial results
    echo "Running serial version..."
    SERIAL_OUTPUT=$(./a2decrypt_serial ciphertext.txt $DICT 2>&1 | grep -E "^serial:" | sort)
    
    # Get parallel results (with 6 processes)
    echo "Running parallel version (6 processes)..."
    PARALLEL_OUTPUT=$(mpiexec -n 6 ./a2decrypt ciphertext.txt $DICT 2>&1 | grep -E "^rank" | sed 's/rank [0-9]*: //' | sort -u)
    
    # Compare results
    if [ "$SERIAL_OUTPUT" == "$PARALLEL_OUTPUT" ]; then
        echo -e "${GREEN}PASSED: Serial and parallel outputs match${NC}"
        echo "Results found:"
        echo "$SERIAL_OUTPUT" | sed 's/serial: /  - /'
        ((PASSED++))
        return 0
    else
        echo -e "${RED}FAILED: Outputs do not match${NC}"
        echo "Serial output:"
        echo "$SERIAL_OUTPUT"
        echo "Parallel output:"
        echo "$PARALLEL_OUTPUT"
        ((FAILED++))
        return 1
    fi
    echo ""
}

# Test with 1 process vs 6 processes
test_consistency() {
    local input_file=$1
    local test_name=$2
    
    echo "Testing consistency: $test_name"
    echo "Input file: $input_file"
    
    # Encrypt the input
    ./a2encrypt "$(cat $input_file)" > /dev/null 2>&1
    
    # Get results with 1 process
    OUTPUT_1=$(mpiexec -n 1 ./a2decrypt ciphertext.txt $DICT 2>&1 | grep -E "^rank" | sed 's/rank [0-9]*: //' | sort -u)
    
    # Get results with 6 processes
    OUTPUT_6=$(mpiexec -n 6 ./a2decrypt ciphertext.txt $DICT 2>&1 | grep -E "^rank" | sed 's/rank [0-9]*: //' | sort -u)
    
    if [ "$OUTPUT_1" == "$OUTPUT_6" ]; then
        echo -e "${GREEN}PASSED: 1 process and 6 processes produce same results${NC}"
        ((PASSED++))
        return 0
    else
        echo -e "${RED}FAILED: Results differ between 1 and 6 processes${NC}"
        echo "1 process output:"
        echo "$OUTPUT_1"
        echo "6 processes output:"
        echo "$OUTPUT_6"
        ((FAILED++))
        return 1
    fi
    echo ""
}

# Run tests
echo "Test 1: 3 unique characters"
test_input "$TEST_DIR/test_3chars.txt" "3 unique characters"

echo "Test 2: 4 unique characters"
test_input "$TEST_DIR/test_4chars.txt" "4 unique characters"

echo "Test 3: Consistency check (1 vs 6 processes)"
test_consistency "$TEST_DIR/test_3chars.txt" "Process count consistency"

echo "=========================================="
echo "Test Summary"
echo "=========================================="
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed!${NC}"
    exit 1
fi

