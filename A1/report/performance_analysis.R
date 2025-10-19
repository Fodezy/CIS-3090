# Performance Analysis Script for CIS*3090 Assignment 1
# Parallel Pi Computation Performance Analysis

library(ggplot2)
library(dplyr)
library(readr)

# Read performance data
serial_data <- read_csv("../serial_results.csv")
task_scaling <- read_csv("../parallel/taskScalling/tasks_12.csv") %>%
  bind_rows(read_csv("../parallel/taskScalling/tasks_24.csv")) %>%
  bind_rows(read_csv("../parallel/taskScalling/tasks_48.csv"))
thread_scaling <- read_csv("../parallel/threadScalling/threads_12.csv") %>%
  bind_rows(read_csv("../parallel/threadScalling/threads_24.csv")) %>%
  bind_rows(read_csv("../parallel/threadScalling/threads_48.csv"))

# Calculate baseline metrics
serial_mean <- mean(serial_data$elapsed_ms)
serial_median <- median(serial_data$elapsed_ms)
serial_sd <- sd(serial_data$elapsed_ms)

cat("Serial Performance Summary:\n")
cat("Mean:", serial_mean, "ms\n")
cat("Median:", serial_median, "ms\n")
cat("Std Dev:", serial_sd, "ms\n")
cat("CV:", (serial_sd/serial_mean)*100, "%\n\n")

# Task Scaling Analysis
task_summary <- task_scaling %>%
  group_by(tasks) %>%
  summarise(
    mean_time = mean(elapsed_ms),
    median_time = median(elapsed_ms),
    sd_time = sd(elapsed_ms),
    speedup = serial_mean / mean_time,
    efficiency = (serial_mean / mean_time) / threads[1] * 100,
    .groups = 'drop'
  )

cat("Task Scaling Analysis:\n")
print(task_summary)

# Thread Scaling Analysis
thread_summary <- thread_scaling %>%
  group_by(threads) %>%
  summarise(
    mean_time = mean(elapsed_ms),
    median_time = median(elapsed_ms),
    sd_time = sd(elapsed_ms),
    speedup = serial_mean / mean_time,
    efficiency = (serial_mean / mean_time) / threads[1] * 100,
    .groups = 'drop'
  )

cat("\nThread Scaling Analysis:\n")
print(thread_summary)

# Create visualizations
# 1. Speedup vs Thread Count
p1 <- ggplot(thread_summary, aes(x = threads, y = speedup)) +
  geom_line(color = "blue", size = 1) +
  geom_point(color = "red", size = 3) +
  geom_hline(yintercept = 1, linetype = "dashed", color = "gray") +
  labs(title = "Speedup vs Thread Count",
       x = "Number of Threads",
       y = "Speedup",
       subtitle = "Fixed 240 tasks, 20B total iterations") +
  theme_minimal() +
  scale_x_continuous(breaks = c(12, 24, 48)) +
  scale_y_continuous(breaks = seq(0, 10, 1))

# 2. Task Granularity Impact
p2 <- ggplot(task_summary, aes(x = tasks, y = speedup)) +
  geom_line(color = "green", size = 1) +
  geom_point(color = "purple", size = 3) +
  labs(title = "Speedup vs Task Count",
       x = "Number of Tasks",
       y = "Speedup",
       subtitle = "Fixed 24 threads, 20B total iterations") +
  theme_minimal() +
  scale_x_continuous(breaks = c(12, 24, 48))

# 3. Efficiency Analysis
p3 <- ggplot(thread_summary, aes(x = threads, y = efficiency)) +
  geom_line(color = "orange", size = 1) +
  geom_point(color = "darkred", size = 3) +
  labs(title = "Parallel Efficiency vs Thread Count",
       x = "Number of Threads",
       y = "Efficiency (%)",
       subtitle = "Efficiency = Speedup / Thread Count * 100") +
  theme_minimal() +
  scale_x_continuous(breaks = c(12, 24, 48)) +
  scale_y_continuous(limits = c(0, 100))

# 4. Performance Distribution
p4 <- ggplot(serial_data, aes(x = elapsed_ms)) +
  geom_histogram(bins = 15, fill = "lightblue", color = "black") +
  geom_vline(xintercept = serial_mean, color = "red", linetype = "dashed", size = 1) +
  geom_vline(xintercept = serial_median, color = "blue", linetype = "dashed", size = 1) +
  labs(title = "Serial Performance Distribution",
       x = "Execution Time (ms)",
       y = "Frequency",
       subtitle = paste("Mean:", round(serial_mean), "ms, Median:", round(serial_median), "ms")) +
  theme_minimal()

# Save plots
ggsave("speedup_vs_threads.png", p1, width = 8, height = 6, dpi = 300)
ggsave("speedup_vs_tasks.png", p2, width = 8, height = 6, dpi = 300)
ggsave("efficiency_analysis.png", p3, width = 8, height = 6, dpi = 300)
ggsave("serial_distribution.png", p4, width = 8, height = 6, dpi = 300)

# Print summary statistics
cat("\n=== PERFORMANCE SUMMARY ===\n")
cat("Best Speedup:", max(c(task_summary$speedup, thread_summary$speedup)), "x\n")
cat("Best Configuration: 24 threads, 24 tasks\n")
cat("Serial Baseline:", serial_mean, "ms\n")
cat("Best Parallel Time:", min(c(task_summary$mean_time, thread_summary$mean_time)), "ms\n")
cat("Theoretical Max Speedup: 24x (perfect parallelization)\n")
cat("Actual Max Speedup:", max(c(task_summary$speedup, thread_summary$speedup)), "x\n")
cat("Efficiency:", round(max(c(task_summary$speedup, thread_summary$speedup))/24*100, 1), "%\n")
