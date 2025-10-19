#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <errno.h> // for error handling

// Task representing one Pi computation job
typedef struct Task {
    long long iterations;
    int taskId;
    struct Task* next;
} Task;

// Thread-safe FIFO queue of tasks
typedef struct TaskQueue {
    Task* head;
    Task* tail;
    size_t size;
    pthread_mutex_t mutex;
    pthread_cond_t cond;
} TaskQueue;

typedef struct ThreadPool {
    pthread_t* threads;
    int numThreads;
    // Shared state
    TaskQueue queue;
    volatile bool shutdown;
    long long tasksEnqueued;
    long long tasksCompleted;
    int availableWorkers;
    bool verboseOutput; // print results per task if true
    struct WorkerCtx* workerCtxArr; // owned array for worker contexts
} ThreadPool;

// Worker context for each thread
typedef struct WorkerCtx {
    ThreadPool* pool;
    int workerIndex;
} WorkerCtx;

// used to lock context when printing to stdout when verbose logging is set to True 
static pthread_mutex_t printMutex = PTHREAD_MUTEX_INITIALIZER;

// helper method to lock the thread wehn printing to stdout to remove DRD errors (data races)
static void printThreadResult(int workerIndex, long long iterations, double pi) {
    pthread_mutex_lock(&printMutex);
    fprintf(stdout, "Thread %d completed computed Pi using %lld iterations, the result is %.12f\n",  // getting DRD errors with this - need to make thread safe 
                       workerIndex, iterations, pi);
    fflush(stdout);
    pthread_mutex_unlock(&printMutex);
}

// Malloc for thread pool
static void* checkedMalloc(size_t bytes) {
    void* p = malloc(bytes);
    if (!p) {
        fprintf(stderr, "Out of memory (requested %zu bytes)\n", bytes);
        exit(EXIT_FAILURE);
    }
    return p;
}

// Serial Pi computation (Leibniz series)
static double computePi(long long iterations) {
    // pi = 4 * ∑{k=0..n-1} (-1)^k / (2k+1)
    double sum = 0.0;
    double sign = 1.0;
    for (long long k = 0; k < iterations; ++k) {
        double denom = (double)(2 * k + 1);
        sum += sign / denom;
        sign = -sign;
    }
    return 4.0 * sum;
}

// TaskQueue Initialization
static void queueInit(TaskQueue* q) {
    q->head = NULL;
    q->tail = NULL;
    q->size = 0;
    if (pthread_mutex_init(&q->mutex, NULL) != 0) {
        perror("pthread_mutex_init");
        exit(EXIT_FAILURE);
    }
    if (pthread_cond_init(&q->cond, NULL) != 0) {
        perror("pthread_cond_init");
        exit(EXIT_FAILURE);
    }
}

// Free any remaining tasks to avoid memory leaks
static void queueDestroy(TaskQueue* q) {
    Task* cur = q->head;
    while (cur) {
        Task* nxt = cur->next;
        free(cur);
        cur = nxt;
    }
    pthread_mutex_destroy(&q->mutex);
    pthread_cond_destroy(&q->cond);
}

// Add a task to the queue
static void queuePush(TaskQueue* q, Task* t) {
    t->next = NULL;
    if (q->tail) {
        q->tail->next = t;
    } else {
        q->head = t;
    }
    q->tail = t;
    q->size += 1;
}

// Remove a task from the queue
static Task* queuePop(TaskQueue* q) {
    Task* t = q->head;
    if (!t) return NULL;
    q->head = t->next;
    if (!q->head) q->tail = NULL;
    q->size -= 1;
    t->next = NULL;
    return t;
}

// Worker routine
static void* workerMain(void* arg) {
    WorkerCtx* ctx = (WorkerCtx*)arg;
    ThreadPool* pool = ctx->pool;
    const int workerIndex = ctx->workerIndex;

    while (true) {
        pthread_mutex_lock(&pool->queue.mutex);
        // Mark available before waiting if no immediate work
        while (pool->queue.size == 0 && !pool->shutdown) {
            pool->availableWorkers += 1;
            pthread_cond_wait(&pool->queue.cond, &pool->queue.mutex);
            // Woken up; now this worker is going to try to get work
            if (pool->availableWorkers > 0) {
                pool->availableWorkers -= 1;
            }
        }
        
        // Only exit if shutdown AND no more work
        if (pool->shutdown && pool->queue.size == 0) {
            pthread_mutex_unlock(&pool->queue.mutex);
            break; // Exit worker
        }
        Task* task = queuePop(&pool->queue);
        pthread_mutex_unlock(&pool->queue.mutex);
        if (task) {
            // Do the work without holding the lock
            double pi = computePi(task->iterations);
            // Update completed count and notify waiters
            pthread_mutex_lock(&pool->queue.mutex);
            pool->tasksCompleted += 1;
            pthread_cond_broadcast(&pool->queue.cond);
            pthread_mutex_unlock(&pool->queue.mutex);
            if (pool->verboseOutput) {
                printThreadResult(workerIndex, task->iterations, pi);
                // fprintf(stdout, "Thread %d completed computed Pi using %lld iterations, the result is %.12f\n",  // getting DRD errors with this - need to make thread safe 
                //        workerIndex, task->iterations, pi);
                // fflush(stdout);
            }
            free(task);
        }
    }
    return NULL;
}

// ThreadPool Initialization
static void threadPoolInit(ThreadPool* pool, int numThreads, bool verboseOutput) {
    pool->numThreads = numThreads;
    pool->threads = (pthread_t*)checkedMalloc(sizeof(pthread_t) * (size_t)numThreads);
    pool->workerCtxArr = (WorkerCtx*)checkedMalloc(sizeof(WorkerCtx) * (size_t)numThreads);
    pool->shutdown = false;
    pool->tasksEnqueued = 0;
    pool->tasksCompleted = 0;
    pool->availableWorkers = 0;
    pool->verboseOutput = verboseOutput;
    queueInit(&pool->queue);

    for (int i = 0; i < numThreads; ++i) {
        WorkerCtx* wctx = &pool->workerCtxArr[i];
        wctx->pool = pool;
        wctx->workerIndex = i + 1; // 1-based index for printing
        int rc = pthread_create(&pool->threads[i], NULL, workerMain, (void*)wctx);
        if (rc != 0) {
            errno = rc;
            perror("pthread_create");
            exit(EXIT_FAILURE);
        }
        // Detach the context from thread lifecycle; worker frees task only; main will free ctx after join
    }
}

// Enqueue a task to the thread pool
static void threadPoolEnqueue(ThreadPool* pool, long long iterations, int taskId) {
    Task* t = (Task*)checkedMalloc(sizeof(Task));
    t->iterations = iterations;
    t->taskId = taskId;
    t->next = NULL;
    pthread_mutex_lock(&pool->queue.mutex);
    queuePush(&pool->queue, t);
    pool->tasksEnqueued += 1;
    // Wake one worker
    pthread_cond_signal(&pool->queue.cond);
    pthread_mutex_unlock(&pool->queue.mutex);
}

// Shutdown and join the thread pool
static void threadPoolShutdownAndJoin(ThreadPool* pool) {
    // Wait for all tasks to complete
    pthread_mutex_lock(&pool->queue.mutex);
    while (pool->tasksCompleted < pool->tasksEnqueued) {
        pthread_cond_wait(&pool->queue.cond, &pool->queue.mutex);
    }
    pool->shutdown = true;
    pthread_cond_broadcast(&pool->queue.cond);
    pthread_mutex_unlock(&pool->queue.mutex);

    // Wait for all threads to finish
    for (int i = 0; i < pool->numThreads; ++i) {
        pthread_join(pool->threads[i], NULL);
    }
}

// Destroy the thread pool
static void threadPoolDestroy(ThreadPool* pool) {
    free(pool->threads);
    free(pool->workerCtxArr);
    queueDestroy(&pool->queue);
}

// Input parsing
static bool parseBoolFlag(const char* s, bool* out) {
    if (s == NULL) return false;
    if (strncmp(s, "true", 4) == 0 || strcmp(s, "1") == 0 || strncmp(s, "yes", 3) == 0) { *out = true; return true; }
    if (strncmp(s, "false", 5) == 0 || strcmp(s, "0") == 0 || strncmp(s, "no", 2) == 0) { *out = false; return true; }
    return false;
}

int main(int argc, char** argv) {
    if (argc < 2 || argc > 3) {
        fprintf(stderr, "Usage: %s fileName [flag]\n", argv[0]);
        return EXIT_FAILURE;
    }

    const char* fileName = argv[1];
    bool verbose = false;
    // Check if the verbose flag is provided
    if (argc == 3) {
        bool tmp;
        if (!parseBoolFlag(argv[2], &tmp)) {
            fprintf(stderr, "Invalid flag: expected true/false or 1/0\n");
            return EXIT_FAILURE;
        }
        verbose = tmp;
    }

    FILE* f = fopen(fileName, "r");
    if (!f) {
        perror("fopen");
        return EXIT_FAILURE;
    }

    int numThreads = 0;
    if (fscanf(f, "%d", &numThreads) != 1 || numThreads <= 0) {
        fprintf(stderr, "Invalid first line: number of threads must be > 0\n");
        fclose(f);
        return EXIT_FAILURE;
    }

    ThreadPool pool;
    threadPoolInit(&pool, numThreads, verbose);

    long long iterations;
    int taskId = 0;
    while (fscanf(f, "%lld", &iterations) == 1) {
        if (iterations < 0) {
            fprintf(stderr, "Ignoring negative iteration count: %lld\n", iterations);
            continue;
        }
        threadPoolEnqueue(&pool, iterations, taskId++);
    }
    fclose(f);
    // Signal condition to help the waiting loop in shutdown notice progress
    threadPoolShutdownAndJoin(&pool);
    threadPoolDestroy(&pool);
    return EXIT_SUCCESS;
}

