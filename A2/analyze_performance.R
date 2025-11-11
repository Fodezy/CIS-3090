#!/usr/bin/env Rscript

# Performance Analysis Script for A2 Decryption
# Generates graphs and statistics from performance test results

library(ggplot2)
library(dplyr)

# Set output directory
output_dir <- "performance_results"
plot_dir <- "performance_plots"
dir.create(plot_dir, showWarnings = FALSE)
dir.create(output_dir, showWarnings = FALSE)

# Check if output directory exists and has files
if (!dir.exists(output_dir)) {
    cat("Error: Directory", output_dir, "does not exist.\n")
    cat("Please run test_performance.sh first to generate data.\n")
    quit(status = 1)
}

# List available files
available_files <- list.files(output_dir, pattern = "\\.csv$")
if (length(available_files) == 0) {
    cat("Warning: No CSV files found in", output_dir, "\n")
    cat("Please run test_performance.sh first to generate data.\n")
    quit(status = 1)
} else {
    cat("Found", length(available_files), "CSV file(s) to analyze.\n")
}

# Function to read and analyze a CSV file
analyze_file <- function(filename, label) {
    filepath <- file.path(output_dir, filename)
    if (!file.exists(filepath)) {
        return(NULL)
    }
    
    data <- read.csv(filepath)
    data$label <- label
    return(data)
}

# Function to calculate statistics
calculate_stats <- function(data) {
    if (is.null(data) || nrow(data) == 0) {
        return(NULL)
    }
    
    stats <- data.frame(
        mean = mean(data$time),
        median = median(data$time),
        sd = sd(data$time),
        min = min(data$time),
        max = max(data$time),
        q25 = quantile(data$time, 0.25),
        q75 = quantile(data$time, 0.75)
    )
    return(stats)
}

# Analyze all test results
cat("Analyzing performance results...\n")

# Collect all data
all_data <- list()
stats_summary <- NULL

# Test up to 5 chars (6 and 7 are commented out for faster testing)
for (num_chars in 3:5) {
    # Serial
    serial_data <- analyze_file(paste0("serial_", num_chars, "chars.csv"), 
                                 paste0("Serial (", num_chars, " chars)"))
    if (!is.null(serial_data)) {
        all_data[[length(all_data) + 1]] <- serial_data
        stats <- calculate_stats(serial_data)
        if (!is.null(stats)) {
            stats$config <- paste0("Serial_", num_chars)
            if (is.null(stats_summary)) {
                stats_summary <- stats
            } else {
                stats_summary <- rbind(stats_summary, stats)
            }
        }
    }
    
    # Parallel 1 process
    par1_data <- analyze_file(paste0("parallel_1proc_", num_chars, "chars.csv"),
                              paste0("Parallel 1 proc (", num_chars, " chars)"))
    if (!is.null(par1_data)) {
        all_data[[length(all_data) + 1]] <- par1_data
        stats <- calculate_stats(par1_data)
        if (!is.null(stats)) {
            stats$config <- paste0("Parallel_1proc_", num_chars)
            if (is.null(stats_summary)) {
                stats_summary <- stats
            } else {
                stats_summary <- rbind(stats_summary, stats)
            }
        }
    }
    
    # Parallel N processes (if exists)
    if (num_chars <= 6) {
        parn_data <- analyze_file(paste0("parallel_", num_chars, "proc_", num_chars, "chars.csv"),
                                  paste0("Parallel ", num_chars, " proc (", num_chars, " chars)"))
        if (!is.null(parn_data)) {
            all_data[[length(all_data) + 1]] <- parn_data
            stats <- calculate_stats(parn_data)
            if (!is.null(stats)) {
                stats$config <- paste0("Parallel_", num_chars, "proc_", num_chars)
                if (is.null(stats_summary)) {
                    stats_summary <- stats
                } else {
                    stats_summary <- rbind(stats_summary, stats)
                }
            }
        }
        
        # Parallel 6 processes
        par6_data <- analyze_file(paste0("parallel_6proc_", num_chars, "chars.csv"),
                                  paste0("Parallel 6 proc (", num_chars, " chars)"))
        if (!is.null(par6_data)) {
            all_data[[length(all_data) + 1]] <- par6_data
            stats <- calculate_stats(par6_data)
            if (!is.null(stats)) {
                stats$config <- paste0("Parallel_6proc_", num_chars)
                if (is.null(stats_summary)) {
                    stats_summary <- stats
                } else {
                    stats_summary <- rbind(stats_summary, stats)
                }
            }
        }
    }
}

# Combine all data
if (length(all_data) > 0) {
    combined_data <- do.call(rbind, all_data)
} else {
    combined_data <- data.frame()
    cat("Warning: No performance data files found in", output_dir, "\n")
    cat("Please run test_performance.sh first to generate data.\n")
    quit(status = 1)
}

# Generate plots
cat("Generating plots...\n")

# Check if we have data
if (is.null(combined_data) || nrow(combined_data) == 0) {
    cat("Error: No data to analyze. Please run test_performance.sh first.\n")
    quit(status = 1)
}

# 1. Execution time comparison by number of characters
if (nrow(combined_data) > 0) {
    # Extract number of chars and config type
    combined_data$num_chars <- as.numeric(gsub(".*\\((\\d+) chars\\)", "\\1", combined_data$label))
    combined_data$config_type <- gsub(" \\(.*", "", combined_data$label)
    
    # Mean execution time by configuration
    mean_times <- combined_data %>%
        group_by(num_chars, config_type) %>%
        summarise(mean_time = mean(time), .groups = 'drop')
    
    p1 <- ggplot(mean_times, aes(x = num_chars, y = mean_time, color = config_type)) +
        geom_line(size = 1) +
        geom_point(size = 2) +
        labs(title = "Mean Execution Time vs Number of Unique Characters",
             x = "Number of Unique Characters",
             y = "Mean Execution Time (seconds)",
             color = "Configuration") +
        theme_minimal() +
        theme(legend.position = "bottom")
    
    ggsave(file.path(plot_dir, "execution_time_comparison.png"), p1, width = 10, height = 6)
    
    # 2. Speedup calculation
    speedup_data <- mean_times %>%
        filter(config_type == "Serial") %>%
        select(num_chars, serial_time = mean_time) %>%
        left_join(
            mean_times %>%
            filter(config_type != "Serial") %>%
            select(num_chars, config_type, parallel_time = mean_time),
            by = "num_chars"
        ) %>%
        mutate(speedup = serial_time / parallel_time)
    
    p2 <- ggplot(speedup_data, aes(x = num_chars, y = speedup, color = config_type)) +
        geom_line(size = 1) +
        geom_point(size = 2) +
        geom_hline(yintercept = 1, linetype = "dashed", color = "red") +
        labs(title = "Speedup vs Number of Unique Characters",
             x = "Number of Unique Characters",
             y = "Speedup (Serial Time / Parallel Time)",
             color = "Configuration") +
        theme_minimal() +
        theme(legend.position = "bottom")
    
    ggsave(file.path(plot_dir, "speedup_comparison.png"), p2, width = 10, height = 6)
    
    # 3. Distribution of execution times for 3 chars
    data_3chars <- combined_data %>% filter(num_chars == 3)
    if (nrow(data_3chars) > 0) {
        p3 <- ggplot(data_3chars, aes(x = time, fill = config_type)) +
            geom_histogram(alpha = 0.7, bins = 20, position = "identity") +
            facet_wrap(~config_type, scales = "free_y") +
            labs(title = "Distribution of Execution Times (3 Unique Characters)",
                 x = "Execution Time (seconds)",
                 y = "Frequency") +
            theme_minimal()
        
        ggsave(file.path(plot_dir, "distribution_3chars.png"), p3, width = 12, height = 6)
    }
    
    # 4. Box plots for all configurations
    p4 <- ggplot(combined_data, aes(x = factor(num_chars), y = time, fill = config_type)) +
        geom_boxplot(alpha = 0.7) +
        labs(title = "Execution Time Distribution by Configuration",
             x = "Number of Unique Characters",
             y = "Execution Time (seconds)",
             fill = "Configuration") +
        theme_minimal() +
        theme(legend.position = "bottom")
    
    ggsave(file.path(plot_dir, "boxplot_all_configs.png"), p4, width = 12, height = 8)
}

# Save statistics summary
if (!is.null(stats_summary) && nrow(stats_summary) > 0) {
    write.csv(stats_summary, file.path(output_dir, "statistics_summary.csv"), row.names = FALSE)
    cat("Statistics summary saved in:", file.path(output_dir, "statistics_summary.csv"), "\n")
} else {
    cat("Warning: No statistics to save.\n")
}

cat("Analysis complete! Plots saved in:", plot_dir, "\n")

