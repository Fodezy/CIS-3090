/* 
 Based on Advanced Programming in the Unix Envitonment, 3ed
 by R. Stevens and S. Rago
 */

#include <limits.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/time.h>

int compareInts(const void *arg1, const void *arg2);
int compareDoubles(const void *arg1, const void *arg2);
double calcTime(struct timeval start);
void invArgsExit(void);

int main(int argc, char* argv[])
{
	long            dataLen;
	struct timeval	start;
	double			elapsed;
    double*         nums;

    if (argc == 1){
        dataLen = 64000000;
    }else if (argc == 2){
        dataLen = atol(argv[1]);
        if (dataLen == 0 ){
            invArgsExit();
        }
    }else{
        invArgsExit();
    }
    printf("Initializing data...\n");
    //Allocate the data buffers
    nums = malloc(dataLen*sizeof(double));

	/*
	 * Create the initial set of numbers to sort.
	 */
	srandom(1);
    for (int i = 0; i < dataLen; i++){
		nums[i] = random();
    }
    printf("Done\n");
    /*
     * Get timing data
     */
	gettimeofday(&start, NULL);
    
    /*
     * Do serial sort
     */

    qsort(nums, dataLen, sizeof(double), compareDoubles);


    /*
     * Get and display elapsed wall time time
     */
    elapsed = calcTime(start);
    
	printf("sort took %.4f seconds\n", elapsed);
    free(nums);

	exit(0);
}

/*
 * Compare two long integers (helper function for heapsort)
 */
int compareInts(const void *arg1, const void *arg2)
{
    long l1 = *(long *)arg1;
    long l2 = *(long *)arg2;
    
    if (l1 == l2)
        return 0;
    else if (l1 < l2)
        return -1;
    else
        return 1;
}

int compareDoubles(const void *arg1, const void *arg2)
{
    double l1 = *(double *)arg1;
    double l2 = *(double *)arg2;
    
    if (l1 == l2)
        return 0;
    else if (l1 < l2)
        return -1;
    else
        return 1;
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