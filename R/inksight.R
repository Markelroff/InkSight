# inksight.R (InkSight)
# ggplot2 helpers that apply the design rules in E. R. Tufte,
# "The Visual Display of Quantitative Information" (2nd ed., 2001).
# Page numbers in comments refer to that book. See references/principles.md.
#
# Security and privacy notes
# - Only dependency: ggplot2 (>= 3.4.0). No network calls, no system calls,
#   no eval(parse()), no global options changed, no files read.
# - The only function that writes to disk is save_vdqi(), which refuses to
#   overwrite existing files unless asked and blanks the PDF title field.

library(ggplot2)

# ---- Palette -------------------------------------------------------------
# Grays carry a natural visual order (p.154). Blue is the single accent
# because most colour-deficient viewers can distinguish it (p.183).
vdqi_ink    <- "grey15"
vdqi_muted  <- "grey65"
vdqi_accent <- "#1F5FAD"

# ---- Theme ---------------------------------------------------------------
# Erase non-data-ink (p.96): no panel box, no background, no grid.
# Serif, upper-and-lower-case type (p.183). Thin lines (p.185).
# Horizontal y-axis title so words read left to right (p.183).
theme_vdqi <- function(base_size = 11, base_family = "serif", legend = FALSE) {
  theme_minimal(base_size = base_size, base_family = base_family) %+replace%
    theme(
      panel.grid         = element_blank(),
      panel.background   = element_blank(),
      plot.background    = element_rect(fill = "white", colour = NA),
      axis.line          = element_blank(),
      axis.ticks         = element_line(colour = vdqi_ink, linewidth = 0.25),
      axis.ticks.length  = unit(3, "pt"),
      axis.text          = element_text(colour = vdqi_ink, size = rel(0.85)),
      axis.title         = element_text(colour = vdqi_ink, size = rel(0.9)),
      axis.title.y       = element_text(angle = 0, vjust = 1, hjust = 1,
                                        margin = margin(r = 6)),  # if used directly
      plot.title         = element_text(hjust = 0, size = rel(1.1),
                                        margin = margin(b = 4)),
      plot.subtitle      = element_text(hjust = 0, colour = "grey30",
                                        margin = margin(b = 8)),
      plot.caption       = element_text(hjust = 0, colour = "grey40",
                                        size = rel(0.75)),
      plot.title.position = "plot",
      plot.caption.position = "plot",
      strip.text         = element_text(hjust = 0, colour = vdqi_ink),
      legend.position    = if (legend) "right" else "none",
      plot.margin        = margin(8, 12, 8, 8)
    )
}

# ---- Labels ----------------------------------------------------------------
# Words read left to right (p.183): the y-axis label is written horizontally
# as the first line above the plot instead of running up the axis.
vdqi_labs <- function(xlab = NULL, ylab = NULL, title = NULL, subtitle = NULL,
                      caption = NULL) {
  sub <- c(subtitle, ylab)
  labs(x = xlab, y = NULL, title = title, caption = caption,
       subtitle = if (length(sub)) paste(sub, collapse = "\n") else NULL)
}

# ---- Range-frame (p.130-132) --------------------------------------------
# Axis lines run only from the data minimum to the data maximum, so the
# frame itself reports the range of each variable.
range_frame <- function(x, y) {
  list(
    annotate("segment", x = min(x, na.rm = TRUE), xend = max(x, na.rm = TRUE),
             y = -Inf, yend = -Inf, colour = vdqi_ink, linewidth = 0.4),
    annotate("segment", y = min(y, na.rm = TRUE), yend = max(y, na.rm = TRUE),
             x = -Inf, xend = -Inf, colour = vdqi_ink, linewidth = 0.4)
  )
}

# ---- Scatterplot with range-frame (p.130-133) ----------------------------
# label: optional column whose non-NA values are written next to points
# (label outliers directly, p.180). Never label with patient identifiers.
vdqi_scatter <- function(df, x, y, label = NULL, xlab = x, ylab = y,
                         title = NULL, subtitle = NULL, caption = NULL) {
  p <- ggplot(df, aes(.data[[x]], .data[[y]])) +
    geom_point(size = 1.4, colour = vdqi_ink) +
    range_frame(df[[x]], df[[y]]) +
    vdqi_labs(xlab, ylab, title, subtitle, caption) +
    theme_vdqi()
  if (!is.null(label)) {
    p <- p + geom_text(data = df[!is.na(df[[label]]), , drop = FALSE],
                       aes(label = .data[[label]]), hjust = -0.15,
                       size = 3, family = "serif", colour = vdqi_ink)
  }
  p
}

# ---- Time-series / lines with direct labels (p.28-39, p.183) -------------
# Each line is named at its right-hand end, so no legend is needed.
# highlight: optional group value drawn in the accent colour.
vdqi_lines <- function(df, x, y, group, highlight = NULL, xlab = x, ylab = y,
                       title = NULL, subtitle = NULL, caption = NULL) {
  df$.col <- if (is.null(highlight)) "ink" else
    ifelse(df[[group]] %in% highlight, "accent", "muted")
  last <- do.call(rbind, lapply(split(df, df[[group]]),
                                function(d) d[which.max(d[[x]]), , drop = FALSE]))
  ggplot(df, aes(.data[[x]], .data[[y]], group = .data[[group]], colour = .col)) +
    geom_line(linewidth = 0.6) +
    geom_text(data = last, aes(label = .data[[group]]), hjust = -0.1,
              size = 3.2, family = "serif") +
    scale_colour_manual(values = c(ink = vdqi_ink, muted = vdqi_muted,
                                   accent = vdqi_accent)) +
    scale_x_continuous(expand = expansion(mult = c(0.02, 0.18))) +
    vdqi_labs(xlab, ylab, title, subtitle, caption) +
    theme_vdqi()
}

# ---- Redesigned bar chart (p.126-129) ------------------------------------
# Bars start at zero (lengths proportional to values, p.56 and p.77),
# sorted by value not alphabet (p.178), no frame, no y-axis line,
# white grid lines through the bars replace ticks (p.127-128).
vdqi_bar <- function(df, category, value, xlab = NULL, ylab = value,
                     title = NULL, subtitle = NULL, caption = NULL) {
  if (any(df[[value]] < 0, na.rm = TRUE)) stop("vdqi_bar expects non-negative values")
  df[[category]] <- reorder(factor(df[[category]]), -df[[value]])
  breaks <- pretty(c(0, max(df[[value]], na.rm = TRUE)))
  breaks <- breaks[breaks > 0 & breaks < max(df[[value]], na.rm = TRUE)]
  ggplot(df, aes(.data[[category]], .data[[value]])) +
    geom_col(width = 0.5, fill = vdqi_muted) +
    geom_hline(yintercept = breaks, colour = "white", linewidth = 0.6) +
    scale_y_continuous(breaks = breaks, expand = expansion(mult = c(0, 0.05))) +
    vdqi_labs(xlab, ylab, title, subtitle, caption) +
    theme_vdqi() +
    theme(axis.ticks = element_blank())
}

# ---- Quartile plot, Tufte's box plot (p.123-125) -------------------------
# Line from minimum to first quartile, gap for the middle half, dot at the
# median, line from third quartile to maximum: the same five numbers as a
# box plot with far less ink.
vdqi_quartile <- function(df, group, value, xlab = group, ylab = value,
                          title = NULL, subtitle = NULL, caption = NULL) {
  s <- do.call(rbind, lapply(split(df[[value]], df[[group]]), function(v) {
    q <- stats::quantile(v, c(0, 0.25, 0.5, 0.75, 1), na.rm = TRUE, names = FALSE)
    data.frame(min = q[1], q1 = q[2], med = q[3], q3 = q[4], max = q[5])
  }))
  s$grp <- factor(rownames(s), levels = rownames(s))
  ggplot(s, aes(x = grp)) +
    geom_segment(aes(xend = grp, y = min, yend = q1), colour = vdqi_ink, linewidth = 0.4) +
    geom_segment(aes(xend = grp, y = q3, yend = max), colour = vdqi_ink, linewidth = 0.4) +
    geom_point(aes(y = med), size = 1.6, colour = vdqi_ink) +
    vdqi_labs(xlab, ylab, title, subtitle, caption) +
    theme_vdqi()
}

# ---- Small multiples (p.168-175) -----------------------------------------
# Same design in every panel, shared scales, so the eye attends only to
# changes in the data.
vdqi_small_multiples <- function(df, x, y, facet, ncol = NULL, xlab = x, ylab = y,
                                 title = NULL, subtitle = NULL, caption = NULL) {
  ggplot(df, aes(.data[[x]], .data[[y]])) +
    geom_line(linewidth = 0.4, colour = vdqi_ink) +
    facet_wrap(vars(.data[[facet]]), ncol = ncol, scales = "fixed") +
    vdqi_labs(xlab, ylab, title, subtitle, caption) +
    theme_vdqi(base_size = 9) +
    theme(panel.spacing = unit(10, "pt"))
}

# ---- Integrity calculations ----------------------------------------------
# Lie Factor = size of effect shown in graphic / size of effect in data (p.57).
# Values outside 0.95-1.05 indicate substantial distortion.
lie_factor <- function(shown_start, shown_end, data_start, data_end) {
  stopifnot(shown_start != 0, data_start != 0, data_end != data_start)
  shown_effect <- (shown_end - shown_start) / shown_start
  data_effect  <- (data_end - data_start) / data_start
  lf <- shown_effect / data_effect
  structure(lf, distorted = lf < 0.95 || lf > 1.05)
}

# Money over time: deflated, standardized units beat nominal units (p.68).
# price_index: same length as values; base: index value of the reference year.
deflate <- function(values, price_index, base = price_index[1], population = NULL) {
  stopifnot(length(values) == length(price_index), all(price_index > 0))
  real <- values * base / price_index
  if (!is.null(population)) {
    stopifnot(length(population) == length(values), all(population > 0))
    real <- real / population
  }
  real
}

# ---- Audit a ggplot object -----------------------------------------------
# Returns a character vector of rule violations (empty = no problems found).
# It checks what can be checked mechanically; the checklist in
# references/principles.md covers the rest.
audit_vdqi <- function(p, width = NULL, height = NULL) {
  issues <- character(0)
  geoms  <- vapply(p$layers, function(l) class(l$geom)[1], character(1))
  if (inherits(p$coordinates, "CoordPolar"))
    issues <- c(issues, "Polar coordinates (pie/donut/rose): use a sorted bar chart or a table instead (p.178).")
  if (any(geoms %in% c("GeomBar", "GeomCol", "GeomArea"))) {
    yr <- ggplot_build(p)$layout$panel_params[[1]]$y.range
    if (!is.null(yr) && (yr[1] > 0 || yr[2] < 0))
      issues <- c(issues, "Bars/areas do not start at zero: lengths are no longer proportional to values (p.56, p.77).")
  }
  th <- ggplot2::theme_get() + p$theme
  grid <- ggplot2::calc_element("panel.grid.major", th)
  if (!inherits(grid, "element_blank") && !is.null(grid$colour) &&
      !grepl("^(grey|gray)(8[5-9]|9[0-9])$|^white$", grid$colour))
    issues <- c(issues, "Grid lines are dark: mute them to light gray or remove them (p.112-116).")
  legend_aes <- c("colour", "fill", "shape", "linetype")
  mapped <- c(names(p$mapping), unlist(lapply(p$layers, function(l) names(l$mapping))))
  if (any(legend_aes %in% mapped) && !identical(th$legend.position, "none"))
    issues <- c(issues, "A legend is shown: label the data directly on the plot where possible (p.183).")
  if (!is.null(width) && !is.null(height) && width < height)
    issues <- c(issues, "Figure is taller than wide: prefer about 1.5 times wider than tall unless the data suggest otherwise (p.190).")
  bg <- ggplot2::calc_element("panel.background", th)
  if (!inherits(bg, "element_blank") && !is.null(bg$fill) && !bg$fill %in% c("white", "#FFFFFF", NA))
    issues <- c(issues, "Shaded plot background is non-data-ink: erase it (p.96).")
  if (is.null(p$labels$x) && is.null(p$labels$y) && is.null(p$labels$subtitle))
    issues <- c(issues, "Axes are unlabeled: label clearly and thoroughly (p.77).")
  issues
}

# ---- Save -----------------------------------------------------------------
# Default 6.5 x 4.33 in (1.5:1, p.190). Vector PDF/SVG for print, PNG at
# 300 dpi for slides. Refuses to overwrite unless overwrite = TRUE.
save_vdqi <- function(p, file, width = 6.5, height = width / 1.5,
                      dpi = 300, overwrite = FALSE) {
  ext <- tolower(tools::file_ext(file))
  if (!ext %in% c("pdf", "png", "svg", "tiff")) stop("Use .pdf, .png, .svg or .tiff")
  if (grepl("(^|[/\\\\])\\.\\.([/\\\\]|$)", file)) stop("Relative '..' paths are not allowed")
  if (file.exists(file) && !overwrite) stop("File exists; set overwrite = TRUE to replace it")
  problems <- audit_vdqi(p, width, height)
  if (length(problems)) warning(paste(c("Design audit:", problems), collapse = "\n  - "))
  if (ext == "pdf") {
    ggsave(file, p, width = width, height = height, units = "in", title = "")
  } else {
    ggsave(file, p, width = width, height = height, units = "in", dpi = dpi)
  }
  invisible(file)
}
