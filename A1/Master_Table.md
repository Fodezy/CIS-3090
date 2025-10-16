
## 🧩 **CIS*3090 Assignment 1 Master Summary Table**

| **Category**                            | **Lecture(s)**                                                                | **Example File(s)**                               | **Key Concepts / Skills**                                                                                                                      | **Relevance to A1**                                                  | **Priority** |
| --------------------------------------- | ----------------------------------------------------------------------------- | ------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------- | ------------ |
| **Thread Basics**                       | **Lecture 3 – Introducing Parallel Programming with Pthreads**                | `threadCreateJoin.c`<br>`threadCreateDetached.c`  | Creating and managing threads with Pthreads (`pthread_create`, `pthread_join`, `pthread_exit`).<br>Understanding detached vs joinable threads. | Required to implement worker threads and main thread control.        | ⭐⭐⭐⭐         |
| **Data vs Task Parallelism**            | **Lecture 2 – Basics of Parallel Programming**                                | `parallelSum.c`, `parallelSort.c`                 | Data parallelism (divide work among threads).<br>Task partitioning using structs with thread IDs and work bounds.                              | Foundation for dividing π computation across workers.                | ⭐⭐⭐⭐         |
| **Workload Distribution**               | **Lecture 2 & 3**                                                             | `parallelSum.c`, `parallelSort.c`, `serialSum.c`  | Even vs uneven workload distribution (`n/p` splitting).<br> Passing arguments via `struct threadArgs`.                                         | Basis for how you’ll assign tasks to worker threads.                 | ⭐⭐⭐⭐         |
| **Shared Memory Concepts**              | **Lecture 3 & 4**                                                             | `counter1.c`, `counter2.c`                        | Threads share memory in a single process.<br> Demonstrates race conditions and mutex protection.                                               | Needed to protect shared queue and counters.                         | ⭐⭐⭐⭐⭐        |
| **Synchronization (Mutexes)**           | **Lecture 4 – Thread Synchronization**                                        | `counter2.c`, `msgqueue.c`, `msgqueueCondition.c` | Protect shared data with `pthread_mutex_lock`/`unlock`.                                                                                        | Used for queue protection and thread availability counters.          | ⭐⭐⭐⭐⭐        |
| **Condition Variables (Wait/Signal)**   | **Lecture 4 – Thread Synchronization**                                        | `msgqueueCondition.c`                             | Producer–consumer pattern using `pthread_cond_wait` and `pthread_cond_signal`.                                                                 | This is your **thread pool + task queue** synchronization model.     | ⭐⭐⭐⭐⭐        |
| **Avoiding Busy Waiting**               | **Lecture 4 – Thread Synchronization**                                        | Compare `msgqueue.c` vs `msgqueueCondition.c`     | `msgqueue.c` shows inefficiency of sleeping/polling; `msgqueueCondition.c` shows correct wait/signal pattern.                                  | Directly applies to your queue design — prevents wasted CPU cycles.  | ⭐⭐⭐⭐         |
| **Critical Sections & Race Conditions** | **Lecture 4**                                                                 | `counter1.c`, `counter2.c`                        | Illustrates when and why races happen.                                                                                                         | Ensures correctness when multiple threads modify global state.       | ⭐⭐⭐⭐         |
| **Thread Pools & Queues**               | **Lecture 4 (Synchronization)**<br>+ conceptual from **Lecture 3 (Pthreads)** | `msgqueueCondition.c` (most similar)              | Persistent worker threads that sleep until work appears; tasks enqueued safely.                                                                | Core of your assignment — the thread pool queue system.              | ⭐⭐⭐⭐⭐        |
| **Program Design Methodology**          | **Lecture 2 – Foster’s Methodology**                                          | `parallelSum.c`, `parallelSort.c`                 | Steps: Partition → Communication → Aggregation → Mapping.<br>Used to structure your design report.                                             | Helps structure your code and analysis discussion.                   | ⭐⭐⭐          |
| **Performance Measurement & Analysis**  | **Lecture 5 – Thinking About Performance**                                    | `parallelSum.c`, `serialSum.c`                    | Using `gettimeofday()` to time runs.<br> Repeating trials, analyzing mean/median, plotting speedup vs cores.                                   | Required for your report: serial vs parallel timings, speedup plots. | ⭐⭐⭐⭐⭐        |
| **Empirical Testing**                   | **Lecture 5**                                                                 | (All timed examples)                              | Collecting multiple data points; variation analysis.                                                                                           | Needed for the 30-repetition timing and performance report.          | ⭐⭐⭐⭐         |
| **Hardware & Scaling Effects**          | **Lecture 6 – Hardware and Parallelism**                                      | —                                                 | Cache effects, hyper-threading, CPU core limits.<br>Explains why performance saturates past core count.                                        | For interpretation in your performance discussion.                   | ⭐⭐⭐          |
| **Parallel Performance Theory**         | **Lecture 2 & 5**                                                             | `parallelSum.c`                                   | O(n/p + log p) reduction complexity.<br>Amdahl’s Law concept (speedup limits).                                                                 | Theoretical justification for performance results.                   | ⭐⭐⭐          |
| **Concurrency vs Parallelism**          | **Lecture 1 – Intro to Parallel Programming**                                 | —                                                 | Conceptual definitions; concurrency can occur on 1 CPU, parallelism requires >1 core.                                                          | Background for your introduction/report.                             | ⭐⭐           |
| **Distributed Systems (MPI)**           | **Lecture 7 – MPI Part 1**                                                    | —                                                 | Message passing interface (MPI) basics.                                                                                                        | Not required — skip for this assignment (shared memory only).        | 🚫           |

---

## 🧠 **How to Use This Table**

### 🔹 Step-by-step study flow

1. **Start with Lectures 3 & 4 + counter/msgqueue files** → Build your conceptual foundation for threads, mutexes, and condition variables.
2. **Then review parallelSum/parallelSort** → Understand argument passing, work partitioning, and timing setup.
3. **Finally, study Lecture 5 + serialSum** → Learn how to test and analyze performance empirically.
4. **Skim Lecture 6** → Use its hardware insights for your report discussion.
5. **Ignore Lecture 7** → Not relevant (MPI = distributed, not shared memory).

---

## ✅ **Key Takeaway Mapping (Concept → Where to Learn It)**

| Concept                       | Learn From Lecture | Reinforced By Example             |
| ----------------------------- | ------------------ | --------------------------------- |
| Thread creation & joining     | Lecture 3          | `threadCreateJoin.c`              |
| Mutex locking for shared data | Lecture 4          | `counter2.c`, `msgqueue.c`        |
| Condition variables           | Lecture 4          | `msgqueueCondition.c`             |
| Safe shared queue             | Lecture 4          | `msgqueueCondition.c`             |
| Workload partitioning         | Lecture 2          | `parallelSum.c`, `parallelSort.c` |
| Performance measurement       | Lecture 5          | `serialSum.c`, `parallelSum.c`    |
| Speedup interpretation        | Lecture 5 & 6      | `parallelSum.c`                   |
| Race condition demonstration  | Lecture 4          | `counter1.c`                      |
| Design methodology            | Lecture 2          | `parallelSum.c`, `parallelSort.c` |
| Serial vs parallel comparison | Lecture 5          | `serialSum.c` vs `parallelSum.c`  |

---

## 🧩 **In Short**

> If you deeply understand:
>
> * `msgqueueCondition.c` (queue + condition logic),
> * `parallelSum.c` (parallel structure),
> * `serialSum.c` (baseline & timing),
> * and Lectures 3–5 (threads, sync, performance),
>
> you’ll have every concept and pattern needed to implement and analyze your Assignment 1 successfully.
