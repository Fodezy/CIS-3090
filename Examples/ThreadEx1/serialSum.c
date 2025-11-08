/* 
 Based on Advanced Programming in the Unix Envitonment, 3ed
 by R. Stevens and S. Rago
 */

#include <stdbool.h>
#include <limits.h>
#include <float.h>
#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <unistd.h>
#include <sys/time.h>

double calcTime(struct timeval start);
void invArgsExit(void);

int main(int argc, char* argv[])
{
    long dataLen;                   /* number of numbers to sum */
	unsigned long	i;
	struct timeval	start;
	double			elapsed;
    double			sum;
    double*         nums;

    if (argc == 1){
        //Defaults
        dataLen = 64000000;
    }else if (argc == 2){
        dataLen = atol(argv[1]);
        if (dataLen == 0 ){
            invArgsExit();
        }
    }else{
        invArgsExit();
    }
    
    //Allocate the data buffers
    nums = malloc(dataLen*sizeof(double));
    
	/*
	 * Create the initial set of numbers to sum.
	 */
    printf("Initializing data...\n");
	srandom(1);
    // for (i = 0; i < NUMNUM; i++){
    for (i = 0; i < dataLen; i++){
        //We keep the individual numbers small to avoid potential overflows
		nums[i] = random() % 10;
    }
    printf("Done\n");

    /*
     * Get timing data
     */
	gettimeofday(&start, NULL);
    
    sum = 0;
    for (i = 0; i < dataLen; i++){
        sum += nums[i] = random() % 10;
    }
    
    elapsed = calcTime(start);
	printf("sum took %.4f seconds\n", elapsed);

    free(nums);

	exit(0);
}

double calcTime(struct timeval start){
    
    long long		startusec, endusec;
    struct timeval	end;
    
    gettimeofday(&end, NULL);
    startusec = start.tv_sec * 1000000 + start.tv_usec;
    endusec = end.tv_sec * 1000000 + end.tv_usec;
    return (double)(endusec - startusec) / 1000000.0;
}


void invArgsExit(void){
    fprintf(stderr, "Incorrect number of arguments\n");
    fprintf(stderr, "Usage: <exec_name> or <exec_name> dataLen.\n");
    fprintf(stderr, "If dataLen is provided, it must be a positive integer.\n");
    fprintf(stderr, "Exiting...\n");
    exit(1);
}
