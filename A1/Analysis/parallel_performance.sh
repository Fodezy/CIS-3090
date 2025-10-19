#!/usr/bin/env bash
set -Eeuo pipefail
mkdir -p parallel/threadScalling parallel/taskScalling


FNAMESOUT=("threads_04"
           "threads_12"
           "threads_18"
           "threads_24"
           "threads_30"
           "threads_48")
THREADS=(
"4"
"12"
"18"
"24"
"30"
"48")
declare -i iter=0

INPUTDIR="Analysis/inputs/threadScalling"
for FILE in "$INPUTDIR"/*.txt; do 


    OUT="parallel/threadScalling/${FNAMESOUT[iter]}.csv"
    : > "$OUT"
    echo "mode,threads,tasks,iters_per_task,total_iters,run_id,elapsed_ms" >> "$OUT"
    echo "Found test input file: $FILE Starting 30 iterations now..." 

    for run in {1..30}; do  
    
        echo "Starting run $run..."
        
        start_time_ms=$(date +%s%3N)  
        ./A1 Analysis/inputs/threadScalling/${FNAMESOUT[iter]}.txt false 
        end_time_ms=$(date +%s%3N) 
        elapsed_ms=$((end_time_ms - start_time_ms))
        
        echo "parallel,${THREADS[iter]},240,83333333,20000000000,$run,$elapsed_ms" >> "$OUT" 
        echo "Run $run completed in ${elapsed_ms} ms."
    done

    iter+=1
done


FNAMESOUT=("tasks_04"
           "tasks_12"
           "tasks_18"
           "tasks_24"
           "tasks_30"
           "tasks_48")
TASKS=(
    "4"
    "12"
    "18"
    "24"
    "30"
    "48"
)
ITERATIONS=(
    "5000000000"
    "1666666667"
    "1111111111"
    "833333334"
    "666666666"
    "416666667"
)
declare -i iter=0
INPUTDIR="Analysis/inputs/taskScalling"
for FILE in "$INPUTDIR"/*.txt; do 


    OUT="parallel/taskScalling/${FNAMESOUT[iter]}.csv"
    : > "$OUT"
    echo "mode,threads,tasks,iters_per_task,total_iters,run_id,elapsed_ms" >> "$OUT"
    echo "Found test input file: $FILE Starting 30 iterations now..." 

    for run in {1..30}; do  
        echo "Starting run $run..."
        start_time_ms=$(date +%s%3N)  

        ./A1 Analysis/inputs/taskScalling/${FNAMESOUT[iter]}.txt false 

        end_time_ms=$(date +%s%3N) 
        elapsed_ms=$((end_time_ms - start_time_ms))
        echo "parallel,24,${TASKS[iter]},${ITERATIONS[iter]},20000000000,$run,$elapsed_ms" >> "$OUT" 
        echo "Run $run completed in ${elapsed_ms} ms."
    done

    iter+=1
done


# ITERATIONS=20000000000 # 20 billion iterations



