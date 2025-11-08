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

long nThr;                      /* number of threads */
long dataLen;                   /* number of numbers to sum */
long *thrDataLen;               /* number of elements to sum per thread */

double *nums;                   /* data */
double *partSums;               /* array for partial sum results */

void * threadFunction(void *arg);
double getRefSum(void);
double merge(void);
double calcTime(struct timeval start);
void invArgsExit(void);

typedef struct {
    long startOffset;
    long thrDataLen;
    int  myTid;
} threadArgs;

int main(int argc, char* argv[])
{
    pthread_t       *tid;
	unsigned long	i;
	struct timeval	start;
	double			elapsed;
	int				err;

    if (argc == 1){
        //Defaults
        nThr = 1;
        dataLen = 64000000;
    }else if (argc == 3){
        nThr = atol(argv[1]);
        dataLen = atol(argv[2]);
        if (nThr == 0 || dataLen == 0 ){
            invArgsExit();
        }
    }else{
        invArgsExit();
    }
    
    //Allocate the data buffers
    tid  = malloc(nThr*sizeof(pthread_t));
    partSums = malloc(nThr*sizeof(double));
    thrDataLen = malloc(nThr*sizeof(long));
    nums = malloc(dataLen*sizeof(double));
    
    
    //We do the even distribution
    
    //Every thread gets floor(dataLen/nThr) data points
    for (int i = 0; i < nThr; i++){
        thrDataLen[i] = dataLen/nThr;
        printf("Assigning %li to thread %d\n", dataLen/nThr, i);
    }

    //A few threads get one extra data point
    long dataCount = (dataLen/nThr) * nThr;
    fprintf(stderr, "dataCount: %li, dataLen %li\n", dataCount, dataLen);
    i = 0;
    while (dataCount < dataLen){
        printf("%li %li\n", dataCount, i);
        thrDataLen[i] += 1;
        dataCount += 1;
        i += 1;
    }
    
    //Let's verify that we've distributed the work correctly
    long sanityCheck = 0;
    for (int i = 0; i < nThr; i++){
        sanityCheck += thrDataLen[i];
    }
  
    for (int i = 0; i < nThr; i++){
        printf("Thread %d is assigned %li data points\n", i, thrDataLen[i]);
    }
    printf("Remaining unassigned data points: %li out of %li\n", dataLen-sanityCheck, dataLen);
    
	/*
	 * Create the initial set of numbers to sum.
	 */
    printf("Initializing data...\n");
	srandom(1);
    // for (i = 0; i < NUMNUM; i++){
    for (i = 0; i < dataLen; i++){
        //We keep the individual numbers small to avoid potential overflows
		nums[i] = random() % 10;
        // printf("%lf\n", nums[i]);
    }
    printf("Done\n");

    /*
     * Get timing data
     */
	gettimeofday(&start, NULL);
    
    /*
     * Create NTHR threads to sum the numbers.
     */

    threadArgs *tArgs;
    long currOffset = 0;
    for (i = 0; i < nThr; i++) {
        //We will pass startimng offest and data length to each thread
        tArgs = malloc(sizeof(threadArgs));
        tArgs->startOffset = currOffset;
        tArgs->thrDataLen = thrDataLen[i];
        tArgs->myTid = i;
        err = pthread_create(&tid[i], NULL, threadFunction, (void *)tArgs);
        if (err != 0){
            printf("Cannot create thread, error: %d", err);
            exit(-1);
        }
        currOffset += thrDataLen[i];
    }
    
    /*
     * Wait for workers to finish and merge the sums
     */
    
    for (int i = 0; i < nThr; i++){
        pthread_join(tid[i], NULL);
    }
    double sum = merge();
    
    /*
     * Get and display elapsed wall time time
     */
    elapsed = calcTime(start);
	printf("sum took %.4f seconds\n", elapsed);

    double refSum = getRefSum();
    printf("Reference sum: %lf, result: %lf\n", refSum, sum);
    // printArrs();
    // checkRes();

    free(tid);
    free(thrDataLen);
    free(nums);
    free(partSums);

	exit(0);
}

/*
 * Worker thread to sum a portion of the set of numbers.
 */
void * threadFunction(void *arg)
{
    threadArgs	*tArgs = (threadArgs*)arg;
    partSums[tArgs->myTid] = 0;
    fprintf(stderr,"thread %d starts at %li, %li points\n", tArgs->myTid, tArgs->startOffset, tArgs->thrDataLen);
    for (long i = tArgs->startOffset; i < tArgs->startOffset+tArgs->thrDataLen; i++){
        partSums[tArgs->myTid] += nums[i];
    }
    
    free(tArgs);
    return((void *)0);
}



/*
 * Merge the sub-sums
 */
double merge(void)
{
    double  sum = 0;
    
    for (int threadID = 0; threadID < nThr; threadID++) {
        sum += partSums[threadID];
    }

    return sum;
}

double calcTime(struct timeval start){
    
    long long		startusec, endusec;
    struct timeval	end;
    
    gettimeofday(&end, NULL);
    startusec = start.tv_sec * 1000000 + start.tv_usec;
    endusec = end.tv_sec * 1000000 + end.tv_usec;
    return (double)(endusec - startusec) / 1000000.0;
}

double getRefSum(void){
    double sum = 0;
    for (long i = 0; i < dataLen; i++){
        sum += nums[i];
    }
    return sum;
}

void invArgsExit(void){
    fprintf(stderr, "Incorrect number of arguments\n");
    fprintf(stderr, "Usage: <exec_name> or <exec_name> nThreads dataLen.\n");
    fprintf(stderr, "If nThreads and dataLen are provided, they must be positive integers.\n");
    fprintf(stderr, "Exiting...\n");
    exit(1);
}
