# Run from the repository root:  Rscript tests/test_inksight.R
# Uses only base R stopifnot(), so no test framework is needed.
source("R/inksight.R")
set.seed(1)

# Lie Factor reproduces the book's fuel-economy example (p.57): about 14.8
lf <- lie_factor(0.6, 5.3, 18.0, 27.5)
stopifnot(round(as.numeric(lf), 1) == 14.8, isTRUE(attr(lf, "distorted")))
stopifnot(!attr(lie_factor(10, 20, 5, 10), "distorted"))

# Deflation to constant and per-capita units (p.65-68)
stopifnot(all.equal(deflate(c(100, 200), c(1, 2)), c(100, 100)))
stopifnot(all.equal(deflate(c(100, 200), c(1, 2), population = c(10, 20)), c(10, 5)))

# Helpers pass their own audit
df  <- data.frame(g = rep(c("A", "B", "C"), each = 20), v = rnorm(60))
bar <- data.frame(k = c("x", "y", "z"), n = c(4, 9, 2))
ts  <- data.frame(t = rep(1:10, 2), y = c(cumsum(rnorm(10)), cumsum(rnorm(10))),
                  s = rep(c("Treated", "Control"), each = 10))
stopifnot(length(audit_vdqi(vdqi_bar(bar, "k", "n"))) == 0)
stopifnot(length(audit_vdqi(vdqi_quartile(df, "g", "v"))) == 0)
stopifnot(length(audit_vdqi(vdqi_scatter(ts, "t", "y"))) == 0)
stopifnot(length(audit_vdqi(vdqi_lines(ts, "t", "y", "s", highlight = "Treated"))) == 0)
stopifnot(length(audit_vdqi(vdqi_small_multiples(ts, "t", "y", "s"))) == 0)

# Audit catches common violations
pie <- ggplot(bar, aes("", n, fill = k)) + geom_col() + coord_polar("y")
stopifnot(any(grepl("Polar", audit_vdqi(pie))), any(grepl("legend", audit_vdqi(pie))))
trunc <- ggplot(bar, aes(k, n)) + geom_col() + coord_cartesian(ylim = c(1, 10))
stopifnot(any(grepl("zero", audit_vdqi(trunc))))
stopifnot(any(grepl("taller", audit_vdqi(vdqi_bar(bar, "k", "n"), width = 3, height = 5))))

# Saving: writes, refuses overwrite, rejects bad extensions and '..'
f <- file.path(tempdir(), "t.png")
if (file.exists(f)) file.remove(f)
save_vdqi(vdqi_bar(bar, "k", "n"), f)
stopifnot(file.exists(f))
stopifnot(inherits(try(save_vdqi(vdqi_bar(bar, "k", "n"), f), silent = TRUE), "try-error"))
stopifnot(inherits(try(save_vdqi(vdqi_bar(bar, "k", "n"), "a.exe"), silent = TRUE), "try-error"))
stopifnot(inherits(try(save_vdqi(vdqi_bar(bar, "k", "n"), "../a.png"), silent = TRUE), "try-error"))
pdf_f <- file.path(tempdir(), "t.pdf")
if (file.exists(pdf_f)) file.remove(pdf_f)
save_vdqi(vdqi_bar(bar, "k", "n"), pdf_f)
stopifnot(!any(grepl("R Graphics Output", readLines(pdf_f, warn = FALSE), useBytes = TRUE)))

cat("All R tests passed\n")
