# Comprehensive Performance Analysis and Visualization
# CIS*3090 Assignment 1 - Parallel Pi Computation

library(ggplot2)
library(dplyr)
library(readr)
library(gridExtra)
library(scales)

# Set working directory to report folder
setwd(".")

# Read performance data
cat("Loading performance data...\n")
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
serial_cv <- (serial_sd/serial_mean) * 100

cat("=== SERIAL BASELINE PERFORMANCE ===\n")
cat("Mean execution time:", round(serial_mean), "ms\n")
cat("Median execution time:", round(serial_median), "ms\n")
cat("Standard deviation:", round(serial_sd), "ms\n")
cat("Coefficient of variation:", round(serial_cv, 1), "%\n")
cat("Range:", min(serial_data$elapsed_ms), "-", max(serial_data$elapsed_ms), "ms\n\n")

# Task Scaling Analysis
cat("=== TASK SCALING ANALYSIS ===\n")
task_summary <- task_scaling %>%
  group_by(tasks) %>%
  summarise(
    mean_time = mean(elapsed_ms),
    median_time = median(elapsed_ms),
    sd_time = sd(elapsed_ms),
    cv = (sd(elapsed_ms) / mean(elapsed_ms)) * 100,
    speedup = serial_mean / mean(elapsed_ms),
    efficiency = (serial_mean / mean(elapsed_ms)) / 24 * 100,
    min_time = min(elapsed_ms),
    max_time = max(elapsed_ms),
    .groups = 'drop'
  ) %>%
  mutate(iterations_per_task = 20000000000 / tasks)

print(task_summary)

# Thread Scaling Analysis
cat("\n=== THREAD SCALING ANALYSIS ===\n")
thread_summary <- thread_scaling %>%
  group_by(threads) %>%
  summarise(
    mean_time = mean(elapsed_ms),
    median_time = median(elapsed_ms),
    sd_time = sd(elapsed_ms),
    cv = (sd(elapsed_ms) / mean(elapsed_ms)) * 100,
    speedup = serial_mean / mean(elapsed_ms),
    efficiency = (serial_mean / mean(elapsed_ms)) / threads * 100,
    min_time = min(elapsed_ms),
    max_time = max(elapsed_ms),
    .groups = 'drop'
  )

print(thread_summary)

# Create comprehensive visualizations

# 1. Serial Performance Distribution
p1 <- ggplot(serial_data, aes(x = elapsed_ms)) +
  geom_histogram(bins = 15, fill = "lightblue", color = "black", alpha = 0.7) +
  geom_vline(xintercept = serial_mean, color = "red", linetype = "dashed", size = 1) +
  geom_vline(xintercept = serial_median, color = "blue", linetype = "dashed", size = 1) +
  labs(title = "Serial Performance Distribution",
       subtitle = paste("Mean:", round(serial_mean), "ms, Median:", round(serial_median), "ms, CV:", round(serial_cv, 1), "%"),
       x = "Execution Time (ms)",
       y = "Frequency") +
  theme_minimal() +
  theme(plot.title = element_text(size = 14, face = "bold"),
        plot.subtitle = element_text(size = 12))

# 2. Speedup vs Thread Count
p2 <- ggplot(thread_summary, aes(x = threads, y = speedup)) +
  geom_line(color = "blue", size = 1.5) +
  geom_point(color = "red", size = 4) +
  geom_hline(yintercept = 1, linetype = "dashed", color = "gray") +
  geom_text(aes(label = paste("Speedup:", round(speedup, 2))), 
            vjust = -0.5, hjust = 0.5, size = 3) +
  labs(title = "Speedup vs Thread Count",
       subtitle = "Fixed 240 tasks, 20B total iterations",
       x = "Number of Threads",
       y = "Speedup") +
  theme_minimal() +
  scale_x_continuous(breaks = c(12, 24, 48)) +
  scale_y_continuous(breaks = seq(0, 10, 1)) +
  theme(plot.title = element_text(size = 14, face = "bold"),
        plot.subtitle = element_text(size = 12))

# 3. Efficiency vs Thread Count
p3 <- ggplot(thread_summary, aes(x = threads, y = efficiency)) +
  geom_line(color = "orange", size = 1.5) +
  geom_point(color = "darkred", size = 4) +
  geom_text(aes(label = paste("Efficiency:", round(efficiency, 1), "%")), 
            vjust = -0.5, hjust = 0.5, size = 3) +
  labs(title = "Parallel Efficiency vs Thread Count",
       subtitle = "Efficiency = Speedup / Thread Count × 100%",
       x = "Number of Threads",
       y = "Efficiency (%)") +
  theme_minimal() +
  scale_x_continuous(breaks = c(12, 24, 48)) +
  scale_y_continuous(limits = c(0, 100)) +
  theme(plot.title = element_text(size = 14, face = "bold"),
        plot.subtitle = element_text(size = 12))

# 4. Task Granularity Impact
p4 <- ggplot(task_summary, aes(x = tasks, y = speedup)) +
  geom_line(color = "green", size = 1.5) +
  geom_point(color = "purple", size = 4) +
  geom_text(aes(label = paste("Speedup:", round(speedup, 2))), 
            vjust = -0.5, hjust = 0.5, size = 3) +
  labs(title = "Speedup vs Task Count",
       subtitle = "Fixed 24 threads, 20B total iterations",
       x = "Number of Tasks",
       y = "Speedup") +
  theme_minimal() +
  scale_x_continuous(breaks = c(12, 24, 48)) +
  theme(plot.title = element_text(size = 14, face = "bold"),
        plot.subtitle = element_text(size = 12))

# 5. Task Granularity Efficiency
p5 <- ggplot(task_summary, aes(x = tasks, y = efficiency)) +
  geom_line(color = "darkgreen", size = 1.5) +
  geom_point(color = "darkviolet", size = 4) +
  geom_text(aes(label = paste("Efficiency:", round(efficiency, 1), "%")), 
            vjust = -0.5, hjust = 0.5, size = 3) +
  labs(title = "Efficiency vs Task Count",
       subtitle = "Fixed 24 threads, 20B total iterations",
       x = "Number of Tasks",
       y = "Efficiency (%)") +
  theme_minimal() +
  scale_x_continuous(breaks = c(12, 24, 48)) +
  scale_y_continuous(limits = c(0, 50)) +
  theme(plot.title = element_text(size = 14, face = "bold"),
        plot.subtitle = element_text(size = 12))

# 6. Performance Variability Analysis
p6 <- ggplot(thread_summary, aes(x = threads, y = cv)) +
  geom_line(color = "red", size = 1.5) +
  geom_point(color = "darkred", size = 4) +
  geom_text(aes(label = paste("CV:", round(cv, 1), "%")), 
            vjust = -0.5, hjust = 0.5, size = 3) +
  labs(title = "Performance Variability vs Thread Count",
       subtitle = "Coefficient of Variation (CV) = Std Dev / Mean × 100%",
       x = "Number of Threads",
       y = "Coefficient of Variation (%)") +
  theme_minimal() +
  scale_x_continuous(breaks = c(12, 24, 48)) +
  theme(plot.title = element_text(size = 14, face = "bold"),
        plot.subtitle = element_text(size = 12))

# 7. Theoretical vs Observed Speedup
theoretical_speedup <- data.frame(
  threads = c(12, 24, 48),
  theoretical = c(12, 24, 48),  # Perfect parallelization
  observed = thread_summary$speedup
)

p7 <- ggplot(theoretical_speedup, aes(x = threads)) +
  geom_line(aes(y = theoretical, color = "Theoretical"), size = 1.5) +
  geom_line(aes(y = observed, color = "Observed"), size = 1.5) +
  geom_point(aes(y = theoretical, color = "Theoretical"), size = 4) +
  geom_point(aes(y = observed, color = "Observed"), size = 4) +
  labs(title = "Theoretical vs Observed Speedup",
       subtitle = "Perfect parallelization vs actual performance",
       x = "Number of Threads",
       y = "Speedup") +
  scale_color_manual(values = c("Theoretical" = "blue", "Observed" = "red")) +
  theme_minimal() +
  scale_x_continuous(breaks = c(12, 24, 48)) +
  theme(plot.title = element_text(size = 14, face = "bold"),
        plot.subtitle = element_text(size = 12),
        legend.title = element_blank())

# 8. Execution Time Comparison
execution_times <- data.frame(
  Configuration = c("Serial", "12 Threads", "24 Threads", "48 Threads"),
  Mean_Time = c(serial_mean, 
                thread_summary$mean_time[thread_summary$threads == 12],
                thread_summary$mean_time[thread_summary$threads == 24],
                thread_summary$mean_time[thread_summary$threads == 48]),
  Type = c("Serial", "Parallel", "Parallel", "Parallel")
)

p8 <- ggplot(execution_times, aes(x = Configuration, y = Mean_Time, fill = Type)) +
  geom_bar(stat = "identity", alpha = 0.8) +
  geom_text(aes(label = paste(round(Mean_Time), "ms")), 
            vjust = -0.5, size = 4) +
  labs(title = "Execution Time Comparison",
       subtitle = "Mean execution time across configurations",
       x = "Configuration",
       y = "Mean Execution Time (ms)") +
  scale_fill_manual(values = c("Serial" = "lightblue", "Parallel" = "lightcoral")) +
  theme_minimal() +
  theme(plot.title = element_text(size = 14, face = "bold"),
        plot.subtitle = element_text(size = 12),
        legend.title = element_blank(),
        axis.text.x = element_text(angle = 45, hjust = 1))

# Save individual plots
ggsave("01_serial_distribution.png", p1, width = 10, height = 6, dpi = 300)
ggsave("02_speedup_vs_threads.png", p2, width = 10, height = 6, dpi = 300)
ggsave("03_efficiency_vs_threads.png", p3, width = 10, height = 6, dpi = 300)
ggsave("04_speedup_vs_tasks.png", p4, width = 10, height = 6, dpi = 300)
ggsave("05_efficiency_vs_tasks.png", p5, width = 10, height = 6, dpi = 300)
ggsave("06_variability_analysis.png", p6, width = 10, height = 6, dpi = 300)
ggsave("07_theoretical_vs_observed.png", p7, width = 10, height = 6, dpi = 300)
ggsave("08_execution_time_comparison.png", p8, width = 10, height = 6, dpi = 300)

# Create combined dashboard
dashboard <- grid.arrange(p1, p2, p3, p4, p5, p6, p7, p8, ncol = 2)
ggsave("09_performance_dashboard.png", dashboard, width = 20, height = 24, dpi = 300)

# Generate summary statistics
cat("\n=== PERFORMANCE SUMMARY ===\n")
cat("Best Speedup:", round(max(c(task_summary$speedup, thread_summary$speedup)), 2), "x\n")
cat("Best Configuration: 48 threads, 240 tasks\n")
cat("Serial Baseline:", round(serial_mean), "ms\n")
cat("Best Parallel Time:", round(min(c(task_summary$mean_time, thread_summary$mean_time))), "ms\n")
cat("Theoretical Max Speedup: 48x (perfect parallelization)\n")
cat("Actual Max Speedup:", round(max(c(task_summary$speedup, thread_summary$speedup)), 2), "x\n")
cat("Efficiency at Best Config:", round(max(c(task_summary$efficiency, thread_summary$efficiency)), 1), "%\n")

# Amdahl's Law Analysis
serial_fraction <- 0.1  # Estimated 10% serial portion
parallel_fraction <- 0.9  # Estimated 90% parallel portion
amdahl_speedup <- function(p) 1 / (serial_fraction + parallel_fraction / p)

cat("\n=== AMDahl's Law Analysis ===\n")
cat("Serial Fraction:", serial_fraction * 100, "%\n")
cat("Parallel Fraction:", parallel_fraction * 100, "%\n")
cat("Theoretical Max Speedup:", round(1/serial_fraction, 1), "x\n")
cat("Observed Max Speedup:", round(max(c(task_summary$speedup, thread_summary$speedup)), 2), "x\n")
cat("Achievement:", round(max(c(task_summary$speedup, thread_summary$speedup)) / (1/serial_fraction) * 100, 1), "% of theoretical\n")

# Create Amdahl's Law plot
threads_range <- seq(1, 48, 1)
amdahl_data <- data.frame(
  threads = threads_range,
  speedup = sapply(threads_range, amdahl_speedup)
)

p9 <- ggplot(amdahl_data, aes(x = threads, y = speedup)) +
  geom_line(color = "blue", size = 1.5) +
  geom_point(data = thread_summary, aes(x = threads, y = speedup), 
             color = "red", size = 4) +
  geom_text(data = thread_summary, aes(x = threads, y = speedup, 
                                       label = paste("Observed:", round(speedup, 2))), 
            vjust = -0.5, hjust = 0.5, size = 3) +
  labs(title = "Amdahl's Law vs Observed Performance",
       subtitle = paste("Serial fraction:", serial_fraction*100, "%, Parallel fraction:", parallel_fraction*100, "%"),
       x = "Number of Threads",
       y = "Speedup") +
  theme_minimal() +
  scale_x_continuous(breaks = seq(0, 48, 8)) +
  scale_y_continuous(breaks = seq(0, 10, 1)) +
  theme(plot.title = element_text(size = 14, face = "bold"),
        plot.subtitle = element_text(size = 12))

ggsave("10_amdahl_law_analysis.png", p9, width = 10, height = 6, dpi = 300)

cat("\n=== ANALYSIS COMPLETE ===\n")
cat("Generated 10 visualization files:\n")
cat("- 01_serial_distribution.png\n")
cat("- 02_speedup_vs_threads.png\n")
cat("- 03_efficiency_vs_threads.png\n")
cat("- 04_speedup_vs_tasks.png\n")
cat("- 05_efficiency_vs_tasks.png\n")
cat("- 06_variability_analysis.png\n")
cat("- 07_theoretical_vs_observed.png\n")
cat("- 08_execution_time_comparison.png\n")
cat("- 09_performance_dashboard.png\n")
cat("- 10_amdahl_law_analysis.png\n")
