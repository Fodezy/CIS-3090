#!/usr/bin/env Rscript

# script to compare serial vs parallel performance
# reads csv files and makes comparison graphs

library(ggplot2)

# directories
results_dir <- "performance_results"
plots_dir <- "performance_plots"

# make plots directory if it doesnt exist
if (!dir.exists(plots_dir)) {
    dir.create(plots_dir)
}

# function to read csv file
read_data <- function(filename) {
    filepath <- file.path(results_dir, filename)
    if (!file.exists(filepath)) {
        return(NULL)
    }
    data <- read.csv(filepath)
    return(data)
}

# function to calculate stats
get_stats <- function(data) {
    if (is.null(data) || nrow(data) == 0) {
        return(NULL)
    }
    return(list(
        mean = mean(data$time),
        median = median(data$time),
        sd = sd(data$time),
        min = min(data$time),
        max = max(data$time)
    ))
}

# collect all comparison data
comparisons <- data.frame()

# test for 3 to 13 characters
for (num_chars in 3:13) {
    # read serial data
    serial_file <- paste0("serial_", num_chars, "chars.csv")
    serial_data <- read_data(serial_file)
    
    if (is.null(serial_data)) {
        next
    }
    
    serial_stats <- get_stats(serial_data)
    if (is.null(serial_stats)) {
        next
    }
    
    # read parallel 1 process
    par1_file <- paste0("parallel_1proc_", num_chars, "chars.csv")
    par1_data <- read_data(par1_file)
    
    # read parallel 6 process (if exists, for num_chars <= 6)
    par6_data <- NULL
    if (num_chars <= 6) {
        par6_file <- paste0("parallel_6proc_", num_chars, "chars.csv")
        par6_data <- read_data(par6_file)
    }
    
    # read parallel N process (if exists, for num_chars >= 7)
    parN_data <- NULL
    if (num_chars >= 7) {
        parN_file <- paste0("parallel_", num_chars, "proc_", num_chars, "chars.csv")
        parN_data <- read_data(parN_file)
    }
    
    # add serial to comparison
    comparisons <- rbind(comparisons, data.frame(
        num_chars = num_chars,
        config = "Serial",
        mean_time = serial_stats$mean,
        median_time = serial_stats$median,
        sd_time = serial_stats$sd,
        min_time = serial_stats$min,
        max_time = serial_stats$max
    ))
    
    # add parallel 1 process
    if (!is.null(par1_data)) {
        par1_stats <- get_stats(par1_data)
        if (!is.null(par1_stats)) {
            comparisons <- rbind(comparisons, data.frame(
                num_chars = num_chars,
                config = "Parallel (1 proc)",
                mean_time = par1_stats$mean,
                median_time = par1_stats$median,
                sd_time = par1_stats$sd,
                min_time = par1_stats$min,
                max_time = par1_stats$max
            ))
        }
    }
    
    # add parallel 6 process
    if (!is.null(par6_data)) {
        par6_stats <- get_stats(par6_data)
        if (!is.null(par6_stats)) {
            comparisons <- rbind(comparisons, data.frame(
                num_chars = num_chars,
                config = "Parallel (6 proc)",
                mean_time = par6_stats$mean,
                median_time = par6_stats$median,
                sd_time = par6_stats$sd,
                min_time = par6_stats$min,
                max_time = par6_stats$max
            ))
        }
    }
    
    # add parallel N process
    if (!is.null(parN_data)) {
        parN_stats <- get_stats(parN_data)
        if (!is.null(parN_stats)) {
            comparisons <- rbind(comparisons, data.frame(
                num_chars = num_chars,
                config = paste0("Parallel (", num_chars, " proc)"),
                mean_time = parN_stats$mean,
                median_time = parN_stats$median,
                sd_time = parN_stats$sd,
                min_time = parN_stats$min,
                max_time = parN_stats$max
            ))
        }
    }
}

# calculate speedup
speedup_data <- data.frame()
for (num_chars in 3:13) {
    serial_row <- comparisons[comparisons$num_chars == num_chars & comparisons$config == "Serial", ]
    if (nrow(serial_row) == 0) {
        next
    }
    serial_mean <- serial_row$mean_time[1]
    
    # compare with parallel 1
    par1_row <- comparisons[comparisons$num_chars == num_chars & comparisons$config == "Parallel (1 proc)", ]
    if (nrow(par1_row) > 0) {
        speedup_data <- rbind(speedup_data, data.frame(
            num_chars = num_chars,
            config = "Parallel (1 proc)",
            speedup = serial_mean / par1_row$mean_time[1]
        ))
    }
    
    # compare with parallel 6 (if exists)
    if (num_chars <= 6) {
        par6_row <- comparisons[comparisons$num_chars == num_chars & comparisons$config == "Parallel (6 proc)", ]
        if (nrow(par6_row) > 0) {
            speedup_data <- rbind(speedup_data, data.frame(
                num_chars = num_chars,
                config = "Parallel (6 proc)",
                speedup = serial_mean / par6_row$mean_time[1]
            ))
        }
    }
    
    # compare with parallel N (if exists)
    if (num_chars >= 7) {
        parN_row <- comparisons[comparisons$num_chars == num_chars & 
                                grepl(paste0("Parallel \\(", num_chars, " proc\\)"), comparisons$config), ]
        if (nrow(parN_row) > 0) {
            speedup_data <- rbind(speedup_data, data.frame(
                num_chars = num_chars,
                config = parN_row$config[1],
                speedup = serial_mean / parN_row$mean_time[1]
            ))
        }
    }
}

# print summary statistics
cat("\n=== Performance Comparison Summary ===\n\n")
print(comparisons)

cat("\n=== Speedup Summary ===\n\n")
print(speedup_data)

# graph 1: mean execution time comparison
if (nrow(comparisons) > 0) {
    p1 <- ggplot(comparisons, aes(x = num_chars, y = mean_time, color = config)) +
        geom_point(size = 3) +
        geom_line(linewidth = 1) +
        labs(
            title = "Mean Execution Time Comparison",
            subtitle = "Serial vs Parallel Versions",
            x = "Number of Unique Characters",
            y = "Mean Execution Time (seconds)",
            color = "Configuration"
        ) +
        theme_minimal() +
        theme(
            plot.title = element_text(size = 14, face = "bold"),
            plot.subtitle = element_text(size = 12),
            axis.title = element_text(size = 11),
            legend.position = "right"
        ) +
        scale_y_continuous(trans = "log10")
    
    ggsave(file.path(plots_dir, "mean_time_comparison.png"), p1, width = 10, height = 6, dpi = 300)
    cat("\nSaved: mean_time_comparison.png\n")
}

# graph 2: speedup comparison
if (nrow(speedup_data) > 0) {
    p2 <- ggplot(speedup_data, aes(x = num_chars, y = speedup, color = config)) +
        geom_point(size = 3) +
        geom_line(linewidth = 1) +
        geom_hline(yintercept = 1, linetype = "dashed", color = "gray") +
        labs(
            title = "Speedup Comparison",
            subtitle = "Speedup = Serial Time / Parallel Time",
            x = "Number of Unique Characters",
            y = "Speedup",
            color = "Configuration"
        ) +
        theme_minimal() +
        theme(
            plot.title = element_text(size = 14, face = "bold"),
            plot.subtitle = element_text(size = 12),
            axis.title = element_text(size = 11),
            legend.position = "right"
        )
    
    ggsave(file.path(plots_dir, "speedup_comparison.png"), p2, width = 10, height = 6, dpi = 300)
    cat("Saved: speedup_comparison.png\n")
}

# graph 3: boxplot comparison for each num_chars
for (num_chars in 3:13) {
    # collect all data for this num_chars
    plot_data <- data.frame()
    
    serial_file <- paste0("serial_", num_chars, "chars.csv")
    serial_data <- read_data(serial_file)
    if (!is.null(serial_data)) {
        serial_data$config <- "Serial"
        plot_data <- rbind(plot_data, serial_data)
    }
    
    par1_file <- paste0("parallel_1proc_", num_chars, "chars.csv")
    par1_data <- read_data(par1_file)
    if (!is.null(par1_data)) {
        par1_data$config <- "Parallel (1 proc)"
        plot_data <- rbind(plot_data, par1_data)
    }
    
    if (num_chars <= 6) {
        par6_file <- paste0("parallel_6proc_", num_chars, "chars.csv")
        par6_data <- read_data(par6_file)
        if (!is.null(par6_data)) {
            par6_data$config <- "Parallel (6 proc)"
            plot_data <- rbind(plot_data, par6_data)
        }
    }
    
    if (num_chars >= 7) {
        parN_file <- paste0("parallel_", num_chars, "proc_", num_chars, "chars.csv")
        parN_data <- read_data(parN_file)
        if (!is.null(parN_data)) {
            parN_data$config <- paste0("Parallel (", num_chars, " proc)")
            plot_data <- rbind(plot_data, parN_data)
        }
    }
    
    if (nrow(plot_data) > 0) {
        p3 <- ggplot(plot_data, aes(x = config, y = time, fill = config)) +
            geom_boxplot() +
            labs(
                title = paste0("Execution Time Distribution (", num_chars, " unique characters)"),
                x = "Configuration",
                y = "Execution Time (seconds)",
                fill = "Configuration"
            ) +
            theme_minimal() +
            theme(
                plot.title = element_text(size = 12, face = "bold"),
                axis.text.x = element_text(angle = 45, hjust = 1),
                legend.position = "none"
            )
        
        filename <- paste0("distribution_", num_chars, "chars.png")
        ggsave(file.path(plots_dir, filename), p3, width = 8, height = 6, dpi = 300)
    }
}

# graph 4: bar chart comparing mean times side by side
if (nrow(comparisons) > 0) {
    p4 <- ggplot(comparisons, aes(x = factor(num_chars), y = mean_time, fill = config)) +
        geom_bar(stat = "identity", position = "dodge") +
        labs(
            title = "Mean Execution Time by Configuration",
            x = "Number of Unique Characters",
            y = "Mean Execution Time (seconds)",
            fill = "Configuration"
        ) +
        theme_minimal() +
        theme(
            plot.title = element_text(size = 14, face = "bold"),
            axis.title = element_text(size = 11),
            legend.position = "right"
        ) +
        scale_y_continuous(trans = "log10")
    
    ggsave(file.path(plots_dir, "mean_time_bar.png"), p4, width = 12, height = 6, dpi = 300)
    cat("Saved: mean_time_bar.png\n")
}

# graph 5: Amdahl's Law comparison
# Amdahl's Law: Speedup = 1 / (S + P/N)
# where S = serial fraction, P = parallel fraction, N = number of processors
if (nrow(speedup_data) > 0) {
    # create theoretical Amdahl's Law curves
    num_procs <- 1:15
    serial_fractions <- c(0.1, 0.2, 0.3, 0.4, 0.5)
    
    amdahl_data <- data.frame()
    for (s in serial_fractions) {
        p_frac <- 1 - s
        speedup <- 1 / (s + p_frac / num_procs)
        amdahl_data <- rbind(amdahl_data, data.frame(
            num_procs = num_procs,
            speedup = speedup,
            serial_frac = paste0("Serial = ", s * 100, "%")
        ))
    }
    
    # prepare actual data for plotting
    # extract number of processors from config names
    actual_data <- data.frame()
    for (i in 1:nrow(speedup_data)) {
        config <- speedup_data$config[i]
        num_proc <- 1
        if (grepl("6 proc", config)) {
            num_proc <- 6
        } else if (grepl("1 proc", config)) {
            num_proc <- 1
        } else {
            # extract number from "Parallel (N proc)"
            match <- regmatches(config, regexpr("\\d+", config))
            if (length(match) > 0) {
                num_proc <- as.numeric(match[1])
            }
        }
        actual_data <- rbind(actual_data, data.frame(
            num_procs = num_proc,
            speedup = speedup_data$speedup[i],
            num_chars = speedup_data$num_chars[i],
            config = config
        ))
    }
    
    # create the plot
    p5 <- ggplot() +
        # theoretical curves
        geom_line(data = amdahl_data, aes(x = num_procs, y = speedup, color = serial_frac), linewidth = 1, alpha = 0.7, linetype = "solid") +
        # actual data points
        geom_point(data = actual_data, aes(x = num_procs, y = speedup), size = 3, color = "black", shape = 16) +
        geom_line(data = actual_data, aes(x = num_procs, y = speedup, group = num_chars), linewidth = 0.5, color = "black", alpha = 0.5, linetype = "dashed") +
        labs(
            title = "Amdahl's Law: Theoretical vs Actual Speedup",
            subtitle = "Comparing theoretical limits with observed performance",
            x = "Number of Processors",
            y = "Speedup",
            color = "Theoretical (Serial Fraction)"
        ) +
        theme_minimal() +
        theme(
            plot.title = element_text(size = 14, face = "bold"),
            plot.subtitle = element_text(size = 12),
            axis.title = element_text(size = 11),
            legend.position = "right"
        ) +
        scale_x_continuous(breaks = 1:15)
    
    ggsave(file.path(plots_dir, "amdahl_law.png"), p5, width = 12, height = 7, dpi = 300)
    cat("Saved: amdahl_law.png\n")
}

cat("\n=== Done! ===\n")
cat("All graphs saved to:", plots_dir, "\n")

