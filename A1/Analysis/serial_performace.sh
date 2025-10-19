#!/usr/bin/env bash
OUT="serial_results.csv"
: > "$OUT"
echo "run_id,iters,elapsed_ms" >> "$OUT"

ITERATIONS=20000000000 # 20 billion iterations
              
for run in {1..30}; do  
    echo "Starting run $run..."
    start_time_ms=$(date +%s%3N)  
    ./baseLinePie "$ITERATIONS" > /dev/null 
    end_time_ms=$(date +%s%3N) 
    elapsed_ms=$((end_time_ms - start_time_ms))
    echo "$run,$ITERATIONS,$elapsed_ms" >> "$OUT" 
    echo "Run $run completed in ${elapsed_ms} ms."
done 