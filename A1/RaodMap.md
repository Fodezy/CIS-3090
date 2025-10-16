# 🧭 **Assignment 1 Development Roadmap (Linked to Master Summary Table)**

---

## 🧩 **Phase 0 – Scaffolding & Input Setup**

**Goal:** Get your program skeleton, argument parsing, and Makefile ready.

**Tasks**

* Parse input file (`#threads`, task list).
* Implement basic validation.
* Create a Makefile with `make A1`.
* Prepare test `.txt` input files.

**Study / Reference Links**

| Resource Type | Source                                         | Why                                               |
| ------------- | ---------------------------------------------- | ------------------------------------------------- |
| Lecture       | **Lecture 2 – Basics of Parallel Programming** | Workload partitioning logic (n/p distribution).   |
| Example Code  | `parallelSum.c`, `parallelSort.c`              | Argument handling, timing setup (`gettimeofday`). |
| Lecture       | **Lecture 5 – Thinking About Performance**     | How to measure runtime for later tests.           |

✅ **Outcome:** You can run `./A1 input.txt [flag]`, read all tasks, and prepare to launch threads.

---

## 🧩 **Phase 1 – Serial π Computation**

**Goal:** Build the single-threaded baseline for correctness and benchmarking.

**Tasks**

* Implement the serial π function (from textbook Section 4.4).
* Test that output converges to 3.1415… for large iteration counts.
* Add timing.

**Study / Reference Links**

| Resource Type | Source                                               | Why                                                |
| ------------- | ---------------------------------------------------- | -------------------------------------------------- |
| Lecture       | **Lecture 5 – Thinking About Performance**           | Measuring runtime and consistency (30-run rule).   |
| Example       | `serialSum.c`                                        | Template for simple computation + timing.          |
| Lecture       | **Lecture 1 – Introduction to Parallel Programming** | Conceptual background: serial vs parallel speedup. |

✅ **Outcome:** A correct, timed serial version — your benchmark for performance analysis.

---

## 🧩 **Phase 2 – Shared Data & Queue Structure**

**Goal:** Design the core data model (task queue, worker pool variables, counters).

**Tasks**

* Define a thread-safe task queue structure.
* Add mutex + condition variable to guard it.
* Create global counters (e.g. available workers, pending tasks).

**Study / Reference Links**

| Resource Type | Source                                 | Why                                                               |
| ------------- | -------------------------------------- | ----------------------------------------------------------------- |
| Lecture       | **Lecture 4 – Thread Synchronization** | Mutex and condition variable fundamentals.                        |
| Example       | `msgqueueCondition.c`                  | Blueprint for your queue’s wait/signal pattern.                   |
| Example       | `counter2.c`                           | Mutex protection of shared counters.                              |
| Lecture       | **Lecture 2 – Foster’s Methodology**   | Clarifies partitioning of producer (main) and consumer (workers). |

✅ **Outcome:** A shared, thread-safe structure ready for worker and producer logic.

---

## 🧩 **Phase 3 – Worker Thread Lifecycle**

**Goal:** Implement worker threads that repeatedly fetch tasks and compute π.

**Tasks**

* Create threads using `pthread_create`.
* Worker waits on condition variable if queue empty.
* Upon receiving a task, compute π, print (if flag=true), then go back to waiting.
* Use `pthread_join` for shutdown.

**Study / Reference Links**

| Resource Type | Source                                                         | Why                                                              |
| ------------- | -------------------------------------------------------------- | ---------------------------------------------------------------- |
| Lecture       | **Lecture 3 – Introducing Parallel Programming with Pthreads** | Thread creation, join, argument passing.                         |
| Example       | `threadCreateJoin.c`                                           | Minimal joinable thread example.                                 |
| Example       | `msgqueueCondition.c`                                          | Proper use of `pthread_cond_wait()` and `pthread_cond_signal()`. |
| Lecture       | **Lecture 4 – Thread Synchronization**                         | Synchronization patterns, avoiding busy waiting.                 |
| Example       | `counter1.c`                                                   | Shows what happens without synchronization (race condition).     |

✅ **Outcome:** A functional thread pool where workers compute tasks and synchronize safely.

---

## 🧩 **Phase 4 – Producer Logic (Main Thread)**

**Goal:** Implement the main thread’s role as the producer of tasks.

**Tasks**

* Enqueue all tasks read from input file.
* Signal condition variable after each enqueue.
* Handle shutdown: once queue empty and all threads idle, broadcast to wake and exit.

**Study / Reference Links**

| Resource Type | Source                                         | Why                                                                      |
| ------------- | ---------------------------------------------- | ------------------------------------------------------------------------ |
| Lecture       | **Lecture 4 – Thread Synchronization**         | How producers wake consumers safely (`pthread_cond_signal`/`broadcast`). |
| Example       | `msgqueueCondition.c`                          | Main acts as producer; same logic applies here.                          |
| Example       | `msgqueue.c`                                   | Shows what happens without condition variables.                          |
| Lecture       | **Lecture 2 – Basics of Parallel Programming** | Ensures proper load balancing (some threads may handle more tasks).      |

✅ **Outcome:** Full producer–consumer system running concurrently and shutting down gracefully.

---

## 🧩 **Phase 5 – Testing & Correctness Verification**

**Goal:** Ensure correctness and memory safety.

**Tasks**

* Validate π values across threads (identical for same iteration count).
* Use `valgrind` and `--tool=drd` to detect leaks and data races.
* Confirm program exits cleanly after all tasks completed.

**Study / Reference Links**

| Resource Type | Source                                 | Why                                         |
| ------------- | -------------------------------------- | ------------------------------------------- |
| Lecture       | **Lecture 4 – Thread Synchronization** | Data race avoidance and locking discipline. |
| Example       | `counter2.c`, `msgqueueCondition.c`    | Correct mutex use.                          |
| Lecture       | **Lecture 3 – Pthreads**               | Thread cleanup and join patterns.           |

✅ **Outcome:** Stable, leak-free, and race-free program.

---

## 🧩 **Phase 6 – Performance Analysis**

**Goal:** Measure and interpret performance empirically.

**Tasks**

* Run serial version for multiple iteration counts (20–30 repetitions).
* Run parallel version under varying:

  * Thread pool sizes (<, =, > #cores).
  * Task counts (few long vs many short).
* Collect timing data (CSV).
* Plot runtime and speedup (R or Python).

**Study / Reference Links**

| Resource Type | Source                                            | Why                                                             |
| ------------- | ------------------------------------------------- | --------------------------------------------------------------- |
| Lecture       | **Lecture 5 – Thinking About Performance**        | Experimental design, runtime variability, statistical analysis. |
| Example       | `parallelSum.c`, `serialSum.c`                    | Timing implementation and speedup comparison.                   |
| Lecture       | **Lecture 6 – Computer Hardware and Parallelism** | Explains diminishing returns beyond physical cores.             |
| Lecture       | **Lecture 2 – Basics of Parallel Programming**    | O(n/p + log p) model for speedup interpretation.                |

✅ **Outcome:** Reliable, data-backed performance results showing parallel efficiency.

---

## 🧩 **Phase 7 – Report & Submission**

**Goal:** Write your A1 report and prepare your final deliverables.

**Tasks**

* Describe design decisions (queue logic, synchronization strategy).
* Summarize correctness verification and tools used (Valgrind/DRD).
* Present performance results (tables, plots, analysis).
* Discuss limits using Amdahl’s Law and Lecture 6 (hardware saturation).
* Package all files + input datasets + Makefile.

**Study / Reference Links**

| Resource Type | Source                                     | Why                                                      |
| ------------- | ------------------------------------------ | -------------------------------------------------------- |
| Lecture       | **Lecture 2 – Foster’s Methodology**       | Framework for explaining design.                         |
| Lecture       | **Lecture 5 – Thinking About Performance** | Statistical analysis and visualization in your report.   |
| Lecture       | **Lecture 6 – Hardware and Parallelism**   | Discussion points for real-world scaling.                |
| Example       | `parallelSum.c`, `serialSum.c`             | Use same output structure and timing display for graphs. |

✅ **Outcome:** Complete submission including working code, performance data, and analysis report.

---

# ✅ **Condensed Mapping Summary**

| **Phase**          | **Main Focus**            | **Linked Lectures** | **Linked Examples**                                       |
| ------------------ | ------------------------- | ------------------- | --------------------------------------------------------- |
| 0 – Scaffolding    | Input parsing & Makefile  | L2, L5              | `parallelSum.c`, `serialSum.c`                            |
| 1 – Serial π       | Baseline computation      | L1, L5              | `serialSum.c`                                             |
| 2 – Shared Data    | Task queue design         | L4, L2              | `msgqueueCondition.c`, `counter2.c`                       |
| 3 – Worker Threads | Thread lifecycle & sync   | L3, L4              | `threadCreateJoin.c`, `msgqueueCondition.c`, `counter1.c` |
| 4 – Producer       | Queue enqueue & signaling | L4, L2              | `msgqueueCondition.c`, `msgqueue.c`                       |
| 5 – Correctness    | Race & memory checks      | L3, L4              | `counter2.c`, `msgqueueCondition.c`                       |
| 6 – Performance    | Timing & speedup analysis | L5, L6, L2          | `parallelSum.c`, `serialSum.c`                            |
| 7 – Report         | Analysis & packaging      | L2, L5, L6          | `parallelSum.c`, `serialSum.c`                            |

