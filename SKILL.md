---
name: inksight
description: Create publication-quality statistical figures (R ggplot2 or Python matplotlib) that follow Edward Tufte's principles from The Visual Display of Quantitative Information, with built-in integrity checks (Lie Factor, zero baselines, deflated money), data-ink minimal styling, and privacy-safe export. Use when asked to make, redesign, critique or audit a chart, plot, graph or figure for a paper, poster, thesis or slide.
---

# InkSight

Every drop of ink earns its place. Build figures that tell the truth about the data with as little non-data ink as possible. The rules come from E. R. Tufte, *The Visual Display of Quantitative Information* (2nd ed., 2001). `references/principles.md` lists every rule with its page number and says which code enforces it.

## Files

- `R/inksight.R`: ggplot2 helpers (default; preferred for R and RStudio users).
- `python/inksight.py`: the same helpers for matplotlib.
- `references/principles.md`: rules, page references and the pre-delivery checklist.
- `tests/`: runnable tests for both languages. `examples/`: demos on simulated data.

## Workflow

1. **Understand the question.** Identify the comparison the figure must answer ("compared to what?", p.74), the variables, units and audience. Ask the user if the purpose is unclear.
2. **Choose the form (p.178-179).**
   - 2 or 3 numbers: write a sentence, no figure.
   - Exact values or many lookups: make a table, rows ordered by value or meaning.
   - Category comparison: `vdqi_bar` / `bar` (never a pie chart).
   - Two continuous variables: `vdqi_scatter` / `scatter` (range-frame, labeled outliers).
   - Distributions by group: `vdqi_quartile` / `quartile_plot`.
   - Change over time: `vdqi_lines` / `lines` (direct labels, optional highlight).
   - Same relationship across many groups: `vdqi_small_multiples` / `small_multiples`.
   - Anything else: build with ggplot2/matplotlib and apply `theme_vdqi()` / `vdqi_style()`.
3. **Check integrity before drawing.** Money across years: convert with `deflate()` and state the base year. If redrawing someone's chart, compute `lie_factor()` and report it.
4. **Build** with the helper. Write a title that states the finding. Put units in the y label. Label outliers and events directly on the plot.
5. **Audit.** Run `audit_vdqi(p, width, height)` (R) or `audit_figure(fig)` (Python), then walk the checklist at the end of `references/principles.md`. Fix every issue or justify it in one line.
6. **Export** with `save_vdqi()` (R) or `save_figure()` (Python): PDF or SVG for print, PNG at 300 dpi for slides, default 1.5:1 aspect ratio. Look at the saved image before delivering it.
7. **Report** briefly: what the figure shows, the form chosen and why, and any audit items that remain.

### R usage

```r
source("R/inksight.R")          # needs ggplot2 >= 3.4.0
p <- vdqi_bar(df, "subtype", "n", ylab = "Tumours",
              title = "Luminal A is the most common subtype")
audit_vdqi(p)                         # character(0) means no issues found
save_vdqi(p, "figure1.pdf")           # refuses to overwrite unless overwrite = TRUE
```

### Python usage

```python
import inksight as ink
with ink.vdqi_style():
    fig, ax = plt.subplots(figsize=ink.DEFAULT_SIZE)
    ink.bar(cats, vals, ylabel="Tumours", title="Luminal A is the most common subtype", ax=ax)
    print(ink.save_figure(fig, "figure1.pdf"))   # returns audit findings
```

## Privacy and security rules (always apply)

- Work only on data the user provides, locally. Never upload data, figures or file paths to any web service, and never fetch remote fonts, styles or packages at run time.
- Never put direct identifiers on a figure: names, MRNs, dates of birth, exact dates of service, addresses or sample IDs that map to people. Use generic labels (Patient A, Site 3) or gene and feature names.
- For clinical or claims data, warn the user when any plotted count represents fewer than 11 individuals, since many data use agreements (for example the CMS cell-size suppression policy) require suppressing such cells.
- Exported files carry no software or creation-date metadata (handled by the save helpers). Do not embed data tables in figure files.
- The helpers use no network, shell, `eval`, or deserialization. Do not add any. Write output only to the path the user chose.

## Style defaults (and where they come from)

- Serif, upper-and-lower-case text; words read left to right, so the y label sits horizontally above the plot (p.183).
- No background, box, or grid; thin axis ticks (p.96, p.112-116, p.185).
- Grays for data, one blue accent that colour-deficient readers can distinguish; never red versus green for an essential contrast (p.154, p.183).
- Direct labels instead of legends (p.180, p.183).
- About 1.5 times wider than tall unless the data suggest another shape (p.190).

These are guides, not dogma: if a rule makes a figure worse for its purpose, break it and say why (p.191).
