#!/usr/bin/env python3
"""
Performance Testing Script for A2 Decryption
Runs each test multiple times and collects timing data (Linux-native)
"""

import os
import time
import subprocess
import csv

# Configuration
DICT = "american-english"
TEST_DIR = "test_inputs"
NUM_RUNS = 30
OUTPUT_DIR = "performance_results"
MAX_CHARS = 14  # upper bound for test files like test_3chars.txt ... test_14chars.txt


def time_run(executable, arguments):
    """Time a single run of an executable (no WSL, Linux-native)."""
    cmd = [executable] + arguments

    start_time = time.perf_counter()
    try:
        subprocess.run(
            cmd,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            check=False,
        )
    except FileNotFoundError:
        # If something is missing, treat as very slow; caller should notice config issues.
        return None
    end_time = time.perf_counter()

    return round(end_time - start_time, 3)


def find_executable(candidates):
    """Return the first existing executable path from a list of candidates, or None."""
    for exe in candidates:
        if os.path.exists(exe) and os.access(exe, os.X_OK):
            return exe
    return None


def run_performance_test(input_file, test_name, num_chars):
    """Run performance test for a given input file."""
    print(f"Running performance test: {test_name} ({num_chars} unique characters)")
    print(f"Running test for input file: {input_file}")
    print(f"Number of runs: {NUM_RUNS}")

    # Read plaintext
    with open(input_file, "r", encoding="utf-8") as f:
        input_text = f.read().strip()

    # Locate executables (Linux-native, no WSL)
    encrypt_exe = find_executable(["./a2encrypt", "a2encrypt"])
    if not encrypt_exe:
        print("  ERROR: Could not find a2encrypt executable!")
        return

    decrypt_serial_exe = find_executable(["./a2decrypt_serial", "a2decrypt_serial"])
    if not decrypt_serial_exe:
        print("  ERROR: Could not find a2decrypt_serial executable!")
        return

    decrypt_exe = find_executable(["./a2decrypt", "a2decrypt"])
    if not decrypt_exe:
        print("  ERROR: Could not find a2decrypt (MPI) executable!")
        return

    # 1) Encrypt once for this input -> ciphertext.txt
    subprocess.run(
        [encrypt_exe, input_text],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        check=False,
    )

    os.makedirs(OUTPUT_DIR, exist_ok=True)

    # 2) Serial runs
    serial_file = os.path.join(OUTPUT_DIR, f"serial_{num_chars}chars.csv")
    print("  Testing serial version...", end="", flush=True)
    with open(serial_file, "w", newline="", encoding="ascii") as f:
        writer = csv.writer(f)
        writer.writerow(["run", "time"])
        for i in range(1, NUM_RUNS + 1):
            elapsed = time_run(decrypt_serial_exe, ["ciphertext.txt", DICT])
            if elapsed is None:
                print("\n  ERROR: Failed to run serial executable.")
                return
            writer.writerow([i, elapsed])
            print(".", end="", flush=True)
    print(f" Done (saved: {os.path.basename(serial_file)})")

    # 3) Parallel runs: n in {1, half(num_chars), num_chars}
    #    Example: 8 -> {1,4,8}; 5 -> {1,2,5}; dedupe automatically.
    n1 = 1
    n2 = max(1, num_chars // 2)
    n3 = num_chars

    procs = sorted({n1, n2, n3})

    for n in procs:
        parallel_file = os.path.join(
            OUTPUT_DIR, f"parallel_{n}proc_{num_chars}chars.csv"
        )
        print(f"  Testing parallel version (n={n})...", end="", flush=True)
        with open(parallel_file, "w", newline="", encoding="ascii") as f:
            writer = csv.writer(f)
            writer.writerow(["run", "time"])
            for i in range(1, NUM_RUNS + 1):
                elapsed = time_run(
                    "mpiexec",
                    ["-n", str(n), decrypt_exe, "ciphertext.txt", DICT],
                )
                if elapsed is None:
                    print(f"\n  ERROR: Failed to run mpiexec with n={n}.")
                    return
                writer.writerow([i, elapsed])
                print(".", end="", flush=True)
        print(f" Done (saved: {os.path.basename(parallel_file)})")

    print()


def main():
    print("=" * 50)
    print("A2 Decryption Performance Tests")
    print("=" * 50)
    print()

    os.makedirs(OUTPUT_DIR, exist_ok=True)

    print("Starting performance tests...")
    print()

    # Loop over expected test files test_3chars.txt ... test_MAXchars.txt
    for num_chars in range(3, MAX_CHARS + 1):
        test_file = os.path.join(TEST_DIR, f"test_{num_chars}chars.txt")
        if os.path.exists(test_file):
            run_performance_test(
                test_file,
                f"{num_chars} unique characters",
                num_chars,
            )
        else:
            print(
                f"Skipping {num_chars} unique characters test - "
                f"test_{num_chars}chars.txt not found"
            )

    print("=" * 50)
    print("Performance tests complete!")
    print(f"Results saved in: {OUTPUT_DIR}/")
    print("=" * 50)


if __name__ == "__main__":
    main()
