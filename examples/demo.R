# Run from the repository root:  Rscript examples/demo.R
# All data below are simulated. No real or patient data are used.
source("R/inksight.R")
set.seed(42)
out <- "examples/output"
dir.create(out, showWarnings = FALSE)
save <- function(p, name, ...) save_vdqi(p, file.path(out, name), overwrite = TRUE, ...)

# 1. Before / after: a default bar chart versus the redesigned bar chart
counts <- data.frame(subtype = c("Basal", "HER2", "LumA", "LumB", "Normal"),
                     n = c(98, 58, 231, 129, 40))
before <- ggplot(counts, aes(subtype, n, fill = subtype)) + geom_col()
after  <- vdqi_bar(counts, "subtype", "n", ylab = "Tumours",
                   title = "Luminal A is the most common subtype in the simulated cohort",
                   caption = "Simulated data (n = 556).")
save(before, "01_bar_before.png")
save(after,  "01_bar_after.png")

# 2. Scatterplot with range-frame and directly labeled outliers
g <- data.frame(id = sprintf("Gene_%02d", 1:60), rna = rnorm(60, 8, 1.5))
g$protein <- 0.8 * g$rna + rnorm(60, 0, 0.6)
g$protein[c(7, 33)] <- g$protein[c(7, 33)] + c(3, -3)
g$lab <- ifelse(abs(resid(lm(protein ~ rna, g))) > 2, g$id, NA)
save(vdqi_scatter(g, "rna", "protein", label = "lab",
                  xlab = "mRNA (log2 TPM)", ylab = "Protein (log2)",
                  title = "Two genes depart from the mRNA-protein trend"),
     "02_scatter_range_frame.png")

# 3. Quartile plot instead of a box plot
d <- data.frame(dose = rep(c("0 mg", "10 mg", "50 mg", "100 mg"), each = 40),
                ldl = c(rnorm(40, 160, 25), rnorm(40, 140, 25),
                        rnorm(40, 115, 22), rnorm(40, 100, 20)))
d$dose <- factor(d$dose, levels = c("0 mg", "10 mg", "50 mg", "100 mg"))
save(vdqi_quartile(d, "dose", "ldl", xlab = "Daily dose", ylab = "LDL (mg/dL)",
                   title = "LDL falls with dose; spread stays similar"),
     "03_quartile_plot.png")

# 4. Time-series with direct labels and one highlighted series
arms <- c("Vehicle", "Drug A", "Drug B", "Drug A + B")
slope <- c(9, 6, 5.5, 2.5)
tv <- do.call(rbind, lapply(seq_along(arms), function(i)
  data.frame(day = 0:21, arm = arms[i],
             vol = 100 + slope[i] * (0:21) + cumsum(rnorm(22, 0, 3)))))
save(vdqi_lines(tv, "day", "vol", "arm", highlight = "Drug A + B",
                xlab = "Day", ylab = "Tumour volume, cubic mm",
                title = "Combination therapy slows tumour growth most"),
     "04_lines_direct_labels.png")

# 5. Small multiples: same design, shared scales
sites <- do.call(rbind, lapply(1:8, function(s)
  data.frame(site = paste("Site", s), week = 1:26,
             enrol = cumsum(rpois(26, lambda = runif(1, 1, 4))))))
save(vdqi_small_multiples(sites, "week", "enrol", "site", ncol = 4,
                          xlab = "Week", ylab = "Enrolled",
                          title = "Cumulative enrolment by site"),
     "05_small_multiples.png", width = 8, height = 4)

# Integrity check example: an exaggerated chart (p.57)
print(lie_factor(shown_start = 0.6, shown_end = 5.3, data_start = 18, data_end = 27.5))
