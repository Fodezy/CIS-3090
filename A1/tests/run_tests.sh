#! /usr/bin/bash

# Goal: write test scenarios. Each should have a header explaining the resson for the test. 

# example: test if program has mem leaks by running with valgrind

# simple test [1 thread: 1 task]: normal run, valgrind run, valgrind with drd run 
# ls
OBJFILE="A1"
TESTDIR="tests/inputs"
declare -i testIter=0
TESTSCENARIOS=("Simple Test [1 thread: 1 task]")
# echo "$FILE"

if [ -e $OBJFILE ]; then
    echo "Cleaning previous build..."
    make clean
    sleep 1

    echo "Building Cleaned executable..."
    make 
else 
    echo "Building Fresh executable..."
    make 
fi

sleep 1
echo -e "\n==================================================================================="
echo "Scenario Description:"
echo -e "Each Scenarios will test for: \n1) Base Run: to check for code correctness, \n2) Valgrind Run: valgrind leak-check=full to check for memory leaks, \n3) DRD Run: valgrind with drd tool to check for data race conditions.\n\n"
sleep 2

echo -e "All Test Scenarios that will be preformed"
for scenario in "${TESTSCENARIOS[@]}"; do 
    echo -e " - $scenario\n"
done

sleep 2
echo -e "===================================================================================\n"

echo -e "Starting Test Scenarios...\n"

for FILE in "$TESTDIR"/*.txt; do 
    # echo "Found test input file: $FILE"
    echo "***** Starting Tests for scenario $testIter: ${TESTSCENARIOS[testIter]} *****" 

    echo -e "----- Base Run ----- "
    ./A1 $FILE true

    echo -e "\n"----- Valgrind Run "----- "
    valgrind --leak-check=full ./A1 $FILE true

    echo -e "\n"----- DRD Run "----- "
    valgrind --tool=drd ./A1 $FILE true
    echo -e "\n" 




    testIter+=1 
    sleep 5

done

# echo -e "***** Simple Test [1 thread: 1 task] *****"
# echo "----- Base Run ----- "
# ./A1 tests/inputs/t0_single_thread_small.txt true

# echo -e "\n"----- Valgrind Run "----- "
# valgrind --leak-check=full ./A1 tests/inputs/t0_single_thread_small.txt true

# echo -e "\n"----- DRD Run "----- "
# valgrind --tool=drd ./A1 tests/inputs/t0_single_thread_small.txt true


# # Runs multiple threads with equal tasks 
# echo "==================================================================================="
# echo -e "\n\nRunning Scenario 1: Multiple Threads with Equal Tasks [8 threads: 8 tasks]\n"
# echo "==================================================================================="
# # Runs base case 
# echo "======================================== Base Run ======================================== "
# ./A1 tests/inputs/t1_many_threads_eaqual_small.txt true

# echo -e "\n======================================== Valgrind Run ======================================== "
# valgrind --leak-check=full ./A1 tests/inputs/t1_many_threads_eaqual_small.txt true

# echo -e "\n======================================== DRD Run ======================================== "
# valgrind --tool=drd ./A1 tests/inputs/t1_many_threads_eaqual_small.txt true