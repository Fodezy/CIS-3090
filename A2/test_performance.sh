#!/bin/bash

# Performance Testing Script for A2 Decryption
# Runs each test 30 times and collects timing data

echo "=========================================="
echo "A2 Decryption Performance Tests"
echo "=========================================="
echo ""

DICT="american-english"
TEST_DIR="test_inputs"
NUM_RUNS=30
OUTPUT_DIR="performance_results"

# Create output directory
mkdir -p $OUTPUT_DIR

# Function to time a single run
time_run() {
    local cmd=$1
    local output_file=$2
    
    # Use time command and extract real time
    # Suppress all output (stdout and stderr) to avoid warnings
    if command -v /usr/bin/time > /dev/null 2>&1; then
        /usr/bin/time -f "%e" -o $output_file bash -c "$cmd" > /dev/null 2>&1
        cat $output_file
    else
        # Fallback: use date command for timing (works on most systems)
        local start=$(date +%s.%N)
        bash -c "$cmd" > /dev/null 2>&1
        local end=$(date +%s.%N)
        # Calculate difference using awk (more portable than bc)
        local elapsed=$(awk "BEGIN {printf \"%.3f\", $end - $start}")
        echo "$elapsed"
    fi
}

# Function to run performance test
run_performance_test() {
    local input_file=$1
    local test_name=$2
    local num_chars=$3
    
    echo "Running performance test: $test_name ($num_chars unique characters)"
    echo "Number of runs: $NUM_RUNS"
    
    # Encrypt the input (suppress all output)
    ./a2encrypt "$(cat $input_file)" > /dev/null 2>&1
    
    # Test serial version
    echo "  Testing serial version..."
    SERIAL_FILE="$OUTPUT_DIR/serial_${num_chars}chars.csv"
    echo "run,time" > $SERIAL_FILE
    for i in $(seq 1 $NUM_RUNS); do
        TIME=$(time_run "./a2decrypt_serial ciphertext.txt $DICT 2>/dev/null" "/tmp/time_serial_$$")
        echo "$i,$TIME" >> $SERIAL_FILE
        echo -n "."
    done
    echo " Done"
    
    # Test parallel version with 1 process
    echo "  Testing parallel version (1 process)..."
    PARALLEL_1_FILE="$OUTPUT_DIR/parallel_1proc_${num_chars}chars.csv"
    echo "run,time" > $PARALLEL_1_FILE
    for i in $(seq 1 $NUM_RUNS); do
        TIME=$(time_run "mpiexec -n 1 ./a2decrypt ciphertext.txt $DICT 2>/dev/null" "/tmp/time_par1_$$")
        echo "$i,$TIME" >> $PARALLEL_1_FILE
        echo -n "."
    done
    echo " Done"
    
    # Test parallel version with optimal processes (equal to num_chars)
    # Commented out for faster testing - uncomment if you need this data
    # if [ $num_chars -le 6 ]; then
    #     echo "  Testing parallel version ($num_chars processes)..."
    #     PARALLEL_N_FILE="$OUTPUT_DIR/parallel_${num_chars}proc_${num_chars}chars.csv"
    #     echo "run,time" > $PARALLEL_N_FILE
    #     for i in $(seq 1 $NUM_RUNS); do
    #         TIME=$(time_run "mpiexec -n $num_chars ./a2decrypt ciphertext.txt $DICT 2>/dev/null" "/tmp/time_par${num_chars}_$$")
    #         echo "$i,$TIME" >> $PARALLEL_N_FILE
    #         echo -n "."
    #     done
    #     echo " Done"
    # fi
    
    # Test parallel version with 6 processes (only for smaller inputs to save time)
    if [ $num_chars -le 4 ]; then
        echo "  Testing parallel version (6 processes)..."
        PARALLEL_6_FILE="$OUTPUT_DIR/parallel_6proc_${num_chars}chars.csv"
        echo "run,time" > $PARALLEL_6_FILE
        for i in $(seq 1 $NUM_RUNS); do
            TIME=$(time_run "mpiexec -n 6 ./a2decrypt ciphertext.txt $DICT 2>/dev/null" "/tmp/time_par6_$$")
            echo "$i,$TIME" >> $PARALLEL_6_FILE
            echo -n "."
        done
        echo " Done"
    fi
    
    echo ""
}

# Run performance tests
echo "Starting performance tests..."
echo ""

run_performance_test "$TEST_DIR/test_3chars.txt" "3 unique characters" 3
run_performance_test "$TEST_DIR/test_4chars.txt" "4 unique characters" 4
run_performance_test "$TEST_DIR/test_5chars.txt" "5 unique characters" 5
# Commented out 6 chars test - takes too long even with 5 runs
# run_performance_test "$TEST_DIR/test_6chars.txt" "6 unique characters" 6

# Test larger inputs (commented out - too slow)
# echo "Testing larger inputs (this may take a while)..."
# echo ""

# Test 7 chars (commented out - too slow, exceeds 5 minute limit)
# echo "Testing 7 unique characters (may take several minutes)..."
# read -p "Continue? (y/n) " -n 1 -r
# echo
# if [[ $REPLY =~ ^[Yy]$ ]]; then
#     run_performance_test "$TEST_DIR/test_7chars.txt" "7 unique characters" 7
# fi

echo "=========================================="
echo "Performance tests complete!"
echo "Results saved in: $OUTPUT_DIR/"
echo "=========================================="

