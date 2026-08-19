#
# HadCRUT Temperature Regression Analysis (HadCRUT4 vs HadCRUT5)
# Analyzes linear regressions across all continuous year ranges (7 - 50 years)
# Upside-down cone geometry: intervals are constrained so that as window length L
# increases, ranges slope inward symmetrically on both boundaries.
#

# Configuration
min_len <- 7    # Minimum consecutive years to evaluate
max_len <- 50   # Maximum consecutive years to evaluate

# Dataset URLs
url_hadcrut4 <- "https://www.metoffice.gov.uk/hadobs/hadcrut4/data/current/time_series/HadCRUT.4.6.0.0.annual_ns_avg.txt"
url_hadcrut5 <- "https://www.metoffice.gov.uk/hadobs/hadcrut5/data/HadCRUT.5.1.0.0/analysis/diagnostics/HadCRUT.5.1.0.0.analysis.summary_series.global.annual.csv"

# Fast simple linear regression helper function
fast_slr <- function(x, y) {
  n <- length(x)
  x_mean <- mean(x)
  y_mean <- mean(y)
  
  dx <- x - x_mean
  dy <- y - y_mean
  
  ss_xx <- sum(dx^2)
  ss_xy <- sum(dx * dy)
  ss_yy <- sum(dy^2)
  
  if (ss_xx == 0) {
    return(c(k = 0, p = 1))
  }
  
  k <- ss_xy / ss_xx
  ss_res <- max(0, ss_yy - k * ss_xy)
  df <- n - 2
  
  if (df <= 0 || ss_res == 0) {
    return(c(k = k, p = 0))
  }
  
  s2 <- ss_res / df
  se_k <- sqrt(s2 / ss_xx)
  
  if (se_k == 0) {
    p <- 0
  } else {
    t_stat <- k / se_k
    p <- 2 * pt(-abs(t_stat), df = df)
  }
  
  c(k = k, p = p)
}

# Color assignment helper
get_color <- function(k, p) {
  if (k >= 0 && p < 0.05) {
    "#E41A1C" # Red: Statistically significant warming
  } else if (k >= 0 && p >= 0.05) {
    "#FF7F00" # Orange: Non-significant warming
  } else if (k < 0 && p >= 0.05) {
    "#377EB8" # Cyan/Blue: Non-significant cooling
  } else {
    "#08306B" # Dark Blue: Statistically significant cooling
  }
}

# General analysis & plotting engine
analyze_hadcrut <- function(name, df_temps, min_len = 7, max_len = 50, prefix = "hadcrut", cone_mode = TRUE) {
  samples <- nrow(df_temps)
  year_first <- min(df_temps$year)
  year_last <- max(df_temps$year)
  max_len <- min(max_len, floor(samples / 2))
  
  message(sprintf("\n--- Analyzing %s: %d years (%d - %d) [Cone mode: %s] ---", 
                  name, samples, year_first, year_last, ifelse(cone_mode, "ON", "OFF")))
  
  # Calculate capacity
  total_possible <- sum(sapply(min_len:max_len, function(w) {
    if (cone_mode) {
      max(0, (samples - 2 * w) - w + 1)
    } else {
      samples - w + 1
    }
  }))
  
  res_year_first <- integer(total_possible)
  res_year_last  <- integer(total_possible)
  res_k          <- numeric(total_possible)
  res_p          <- numeric(total_possible)
  
  idx <- 0
  for (w_len in seq(min_len, max_len)) {
    if (cone_mode) {
      # Upside-down cone: starting index is w_len, ending index is samples - 2 * w_len
      i_start <- w_len
      i_end <- samples - 2 * w_len
    } else {
      i_start <- 1
      i_end <- samples - w_len + 1
    }
    
    if (i_start <= i_end) {
      for (i in seq(i_start, i_end)) {
        idx <- idx + 1
        sub_df <- df_temps[i:(i + w_len - 1), ]
        
        fit <- fast_slr(sub_df$year, sub_df$temp)
        
        res_year_first[idx] <- sub_df$year[1]
        res_year_last[idx]  <- sub_df$year[w_len]
        res_k[idx]          <- fit["k"]
        res_p[idx]          <- fit["p"]
      }
    }
  }
  
  results <- data.frame(
    year_first = res_year_first[1:idx],
    year_last  = res_year_last[1:idx],
    k          = res_k[1:idx],
    p          = res_p[1:idx]
  )
  
  n_total <- nrow(results)
  n_inc_sig    <- sum(results$k >= 0 & results$p < 0.05)
  n_inc_nonsig <- sum(results$k >= 0 & results$p >= 0.05)
  n_dec_nonsig <- sum(results$k < 0  & results$p >= 0.05)
  n_dec_sig    <- sum(results$k < 0  & results$p < 0.05)
  
  cat(sprintf("Total regressions tested: %d\n", n_total))
  cat(sprintf("  Warming (p < 0.05):  %4d (%5.1f%%)\n", n_inc_sig, 100 * n_inc_sig / n_total))
  cat(sprintf("  Warming (p >= 0.05): %4d (%5.1f%%)\n", n_inc_nonsig, 100 * n_inc_nonsig / n_total))
  cat(sprintf("  Cooling (p >= 0.05): %4d (%5.1f%%)\n", n_dec_nonsig, 100 * n_dec_nonsig / n_total))
  cat(sprintf("  Cooling (p < 0.05):  %4d (%5.1f%%)\n", n_dec_sig, 100 * n_dec_sig / n_total))
  
  # Plot 1: Cone Range Plot
  r_plot <- results[order(results$p, decreasing = TRUE), ]
  colors <- mapply(get_color, r_plot$k, r_plot$p)
  
  png_range <- sprintf("chart-%s.png", prefix)
  png(png_range, width = 1200, height = 800, res = 120)
  plot(
    c(year_first, year_last),
    c(min_len, max_len + 1),
    type = "n",
    main = sprintf("Linear regression of %s, upside-down cone (%d-%d)", name, year_first, year_last),
    xlab = "Year",
    ylab = sprintf("Year range size (%d - %d years)", min_len, max_len),
    las = 1
  )
  grid(nx = NULL, ny = NA, col = "gray90", lty = "dotted")
  
  # Draw cone boundary guide lines if in cone mode
  if (cone_mode) {
    w_seq <- c(min_len, max_len)
    left_cone_x  <- year_first + w_seq - 1
    right_cone_x <- year_last - w_seq
    lines(left_cone_x, w_seq, col = "gray75", lty = "dashed", lwd = 1)
    lines(right_cone_x, w_seq, col = "gray75", lty = "dashed", lwd = 1)
  }
  
  set.seed(42)
  y_lens <- r_plot$year_last - r_plot$year_first + 1
  y_jitters <- y_lens + runif(nrow(r_plot), min = 0, max = 0.9)
  
  segments(
    x0 = r_plot$year_first,
    y0 = y_jitters,
    x1 = r_plot$year_last,
    y1 = y_jitters,
    lwd = 0.5,
    col = colors
  )
  dev.off()
  message(sprintf("Saved %s", png_range))
  
  # Plot 2: Summary Barplot
  counts <- c(n_inc_sig, n_inc_nonsig, n_dec_nonsig, n_dec_sig)
  bar_colors <- c("#E41A1C", "#FF7F00", "#377EB8", "#08306B")
  bar_labels <- c("Warming (p < 0.05)", "Warming (p \u2265 0.05)", "Cooling (p \u2265 0.05)", "Cooling (p < 0.05)")
  
  png_bar <- sprintf("barchart-%s.png", prefix)
  png(png_bar, width = 900, height = 700, res = 120)
  par(mar = c(5, 5, 4, 2))
  bp <- barplot(
    counts,
    names.arg = bar_labels,
    col = bar_colors,
    main = sprintf("Linear Regressions Distribution (%s: %d-%d)", name, year_first, year_last),
    ylab = "Number of Ranges",
    ylim = c(0, max(counts) * 1.15),
    las = 1,
    cex.names = 0.85
  )
  text(bp, counts + max(counts) * 0.04, labels = sprintf("%d\n(%.1f%%)", counts, 100 * counts / n_total), cex = 0.85)
  grid(nx = NA, ny = NULL, col = "gray90", lty = "dotted")
  dev.off()
  message(sprintf("Saved %s", png_bar))
  
  return(list(
    name = name,
    prefix = prefix,
    year_first = year_first,
    year_last = year_last,
    n_total = n_total,
    counts = counts,
    results = results
  ))
}

#
# 1. Load Datasets
#
message("Fetching HadCRUT4 dataset from Met Office...")
raw_h4 <- read.table(url_hadcrut4, stringsAsFactors = FALSE)
df_h4 <- data.frame(
  year = as.integer(raw_h4[, 1]),
  temp = as.numeric(raw_h4[, 2])
)
df_h4 <- df_h4[!is.na(df_h4$year) & !is.na(df_h4$temp), ]

message("Fetching HadCRUT5 dataset from Met Office...")
raw_h5 <- read.csv(url_hadcrut5, stringsAsFactors = FALSE, check.names = FALSE)
df_h5 <- data.frame(
  year = as.integer(raw_h5[, 1]),
  temp = as.numeric(raw_h5[, 2])
)
df_h5 <- df_h5[!is.na(df_h5$year) & !is.na(df_h5$temp), ]

# Filter HadCRUT5 to match HadCRUT4 date range (1850-2021)
df_h5_2021 <- df_h5[df_h5$year >= 1850 & df_h5$year <= 2021, ]

#
# 2. Run Analyses for all 3 Scenarios
#
res_h4       <- analyze_hadcrut("HadCRUT4 (1850-2021)", df_h4, min_len, max_len, prefix = "hadcrut4", cone_mode = TRUE)
res_h5_2021  <- analyze_hadcrut("HadCRUT5 (1850-2021)", df_h5_2021, min_len, max_len, prefix = "hadcrut5-2021", cone_mode = TRUE)
res_h5_full  <- analyze_hadcrut("HadCRUT5 (1850-2026)", df_h5, min_len, max_len, prefix = "hadcrut5-2026", cone_mode = TRUE)

#
# 3. 3-Way Comparative Barchart
#
comparison_matrix <- cbind(
  "HadCRUT4\n(1850-2021)" = res_h4$counts,
  "HadCRUT5\n(1850-2021)" = res_h5_2021$counts,
  "HadCRUT5\n(1850-2026)" = res_h5_full$counts
)
rownames(comparison_matrix) <- c("Warming (p < 0.05)", "Warming (p \u2265 0.05)", "Cooling (p \u2265 0.05)", "Cooling (p < 0.05)")

png("barchart-comparison.png", width = 1200, height = 800, res = 120)
par(mar = c(6, 5, 4, 2))
bar_colors <- c("#E41A1C", "#FF7F00", "#377EB8", "#08306B")

bp_comp <- barplot(
  comparison_matrix,
  beside = TRUE,
  col = bar_colors,
  main = "Comparison: HadCRUT4 (1850-2021) vs HadCRUT5 (1850-2021) vs HadCRUT5 (1850-2026)",
  ylab = "Number of Ranges (Upside-down Cone)",
  ylim = c(0, max(comparison_matrix) * 1.25),
  las = 1
)

# Add value labels over each bar
text(
  bp_comp,
  as.vector(comparison_matrix) + max(comparison_matrix) * 0.04,
  labels = as.vector(comparison_matrix),
  cex = 0.75
)

legend(
  "topright",
  legend = rownames(comparison_matrix),
  fill = bar_colors,
  bty = "n",
  cex = 0.85
)
grid(nx = NA, ny = NULL, col = "gray90", lty = "dotted")
dev.off()
message("Saved barchart-comparison.png")

#
# 4. 3-Panel Upside-Down Cone Comparison Chart
#
png("chart-comparison.png", width = 1400, height = 1500, res = 120)
par(mfrow = c(3, 1), mar = c(4, 4.5, 3, 2))

plot_cone_panel <- function(res, x_max_year = 2026) {
  r <- res$results[order(res$results$p, decreasing = TRUE), ]
  plot(
    c(1850, x_max_year),
    c(min_len, max_len + 1),
    type = "n",
    main = sprintf("%s (Tested ranges: %d)", res$name, res$n_total),
    xlab = "Year",
    ylab = "Window (Years)",
    las = 1
  )
  grid(nx = NULL, ny = NA, col = "gray90", lty = "dotted")
  
  # Dashed cone boundaries
  w_seq <- c(min_len, max_len)
  lines(res$year_first + w_seq - 1, w_seq, col = "gray75", lty = "dashed", lwd = 1)
  lines(res$year_last - w_seq, w_seq, col = "gray75", lty = "dashed", lwd = 1)
  
  set.seed(42)
  y_lens <- r$year_last - r$year_first + 1
  y_jit <- y_lens + runif(nrow(r), 0, 0.9)
  segments(r$year_first, y_jit, r$year_last, y_jit, lwd = 0.4, col = mapply(get_color, r$k, r$p))
}

plot_cone_panel(res_h4, 2026)
plot_cone_panel(res_h5_2021, 2026)
plot_cone_panel(res_h5_full, 2026)

dev.off()
message("Saved chart-comparison.png")
