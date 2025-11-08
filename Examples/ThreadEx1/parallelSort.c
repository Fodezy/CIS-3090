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
long dataLen;                   /* number of numbers to sort */
long *thrDataLen;               /* number of elements to sort per thread */

double *nums;                     /* unsorted data */
double *origNums;
double *refNums;
double *snums;                    /* sorted data */

int compareInts(const void *arg1, const void *arg2);
int compareDoubles(const void *arg1, const void *arg2);
void * threadFunction(void *arg);
void merge(void);
double calcTime(struct timeval start);
void invArgsExit(void);
bool checkRes(void);
void printArrs(void);

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
    thrDataLen = malloc(nThr*sizeof(long));
    nums = malloc(dataLen*sizeof(double));
    snums = malloc(dataLen*sizeof(double));
    origNums = malloc(dataLen*sizeof(double));
    refNums = malloc(dataLen*sizeof(double));
    
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
	 * Create the initial set of numbers to sort.
	 */
	srandom(1);
    // for (i = 0; i < NUMNUM; i++){
    for (i = 0; i < dataLen; i++){
		nums[i] = random();
        origNums[i] = nums[i];
        refNums[i] = nums[i];
        // printf("%lf\n", nums[i]);
    }
   
    // qsort(refNums, dataLen, sizeof(long), compareDoubles);

    /*
     * Get timing data
     */
	gettimeofday(&start, NULL);
    
    /*
     * Create NTHR threads to sort the numbers.
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
     * Wait for workers to finish and merge the sorted sub-arrays
     */
    
    for (int i = 0; i < nThr; i++){
        pthread_join(tid[i], NULL);
    }
    merge();
    
    /*
     * Get and display elapsed wall time time
     */
    elapsed = calcTime(start);
	printf("sort took %.4f seconds\n", elapsed);

    // printArrs();
    // checkRes();

    free(tid);
    free(thrDataLen);
    free(nums);
    free(snums);
    free(origNums);
    free(refNums);

	exit(0);
}

/*
 * Compare two long integers (helper function for quicksort)
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

/*
 * Worker thread to sort a portion of input data.
 */
void * threadFunction(void *arg)
{
    threadArgs	*tArgs = (threadArgs*)arg;
    fprintf(stderr,"thread %d starts at %li, %li points\n", tArgs->myTid, tArgs->startOffset, tArgs->thrDataLen);
    qsort(&nums[tArgs->startOffset], tArgs->thrDataLen, sizeof(double), compareDoubles);
    free(tArgs);
    return((void *)0);
}



/*
 * Merge the results of the individual sorts - i.e. sorted sub-arrays
 */
void merge(void)
{
    long	*threadOffset = malloc(nThr * sizeof(long));
    long	*threadEnd = malloc(nThr * sizeof(long));
    
    threadOffset[0] = 0;
    threadEnd[0] = thrDataLen[0]-1;
    for (int i = 1; i < nThr; i++){
        threadOffset[i] = thrDataLen[i-1] + threadOffset[i-1];
        threadEnd[i] = threadOffset[i] + thrDataLen[i]-1;
    }

    // for (int i = 0; i < nThr; i++){
    //     printf("Thread %d from %li to %li, %li elements\n", i, threadOffset[i], threadEnd[i], thrDataLen[i]);
    // }
    
    for (long sindex = 0; sindex < dataLen; sindex++) {
        double minVal = DBL_MAX;
        // double minVal = -1;
        int minThrIndex = 0;
        for (int threadID = 0; threadID < nThr; threadID++) {
            //Find the smallest value in the current postions of sorted sub-arrays
            //Do not exceed the sub-array boundaries
            long currOffset = threadOffset[threadID];
            long currEnd = threadEnd[threadID];
            // printf("Looking at thread %d, currOffset %li, currEnd %li\n", threadID, currOffset, currEnd);
            if ( currOffset <= currEnd && nums[currOffset] < minVal ){
                minVal = nums[currOffset];
                minThrIndex = threadID;
                // printf("Found %lf at %li\n", minVal, currOffset);
            }
        }
        //Store the min value
        snums[sindex] = nums[threadOffset[minThrIndex]];
        // printf("Found min value %lf at nums[%li] (thread %d), moving to snums[%li]\n", snums[sindex], threadOffset[minThrIndex], minThrIndex, sindex );
        //Increment the start offset for the sub-array where the min value was
        threadOffset[minThrIndex] += 1;
    }

    free(threadOffset);
    free(threadEnd);
}

double calcTime(struct timeval start){
    
    long long		startusec, endusec;
    struct timeval	end;
    
    gettimeofday(&end, NULL);
    startusec = start.tv_sec * 1000000 + start.tv_usec;
    endusec = end.tv_sec * 1000000 + end.tv_usec;
    return (double)(endusec - startusec) / 1000000.0;
}

bool checkRes(void){
    for (long i = 0; i < dataLen; i++){
        if (snums[i] != refNums[i]){
            printf("Invalid sorting!\n");
            return false;
        }
    }
    return true;
}

void printArrs(void){
    printf("Original data\t\tpart-sorted data\tsorted data\t\treference data\n");
    for (long i = 0; i < dataLen; i++){
       printf("%.0lf\t\t%.0lf\t\t%.0lf\t\t%.0lf\n", origNums[i], nums[i], snums[i], refNums[i]);
    }
}

void invArgsExit(void){
    fprintf(stderr, "Incorrect number of arguments\n");
    fprintf(stderr, "Usage: <exec_name> or <exec_name> nThreads dataLen.\n");
    fprintf(stderr, "If nThreads and dataLen are provided, they must be positive integers.\n");
    fprintf(stderr, "Exiting...\n");
    exit(1);
}
