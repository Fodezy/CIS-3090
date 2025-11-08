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

## Running Test Script
- Setting up shell scripts as executable:
  - `chmod +x tests/run_tests.sh`
    - if you get a permission error just move onto running the test, it should still work

- Running Tests:
  - `./tests/run_tests.sh`
  - This script will either build A1 fresh or clean and rebuild to ensure object file exists
  - Logs for this test file will be redirected from the Terminal to the file: `A1/tests/test_results.log`

## Running performance scripts
- Setting up shell scripts as executable:
  - `chmod +x Analysis/serial_performance.sh`
  - `chmod +x Analysis/parallel_performance.sh`
    - if you get a permission error just move onto running the test, it should still work
    

- Running analysis scripts 
  - `./Analysis/serial_performance.sh`
  - `./Analysis/parallel_performance.sh`

## Project Folder Structure

- Analysis contains: 
  - Inputs folder: Contains the thread scalling and task scalling input files 
  - Outputs folder: Contains the thread scalling and task scalling csv data derived from running the program over 30 iterations each 
  - parallel_performance.sh: contains the shell script used to iterate each call to our parallel program using varying input data, and outputs csv data 
  - serial_performance.sh: contains the shell script used to iterate 30 calls to the serial computation of pi, outputs data to a csv used as out baseline 

- inputs: Contains a sample file used to test out our program, can add other input files here as you wish 

- Report: Contains the written report about this project, containing detailed info on our program implementation, tests, and analysis on performance compared to serial. 

- src: Contains the source code for A1 (parallel project) and baseLinePi (serial project)

- tests contains:
  - inputs: the diffrent input scenarios we wanted to test 
  - run_tests.sh: the shell script to run all the tests, explains scenarios and tracks completion of each test scenario
  - test_results.log: the output from each scenario is logged here for visability, readability, and preservation

- Makefile: contains the targets to build, execute and clean our projects 

