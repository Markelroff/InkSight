# Principles and how this skill enforces them

Source: Edward R. Tufte, *The Visual Display of Quantitative Information*, 2nd ed. (Cheshire, CT: Graphics Press, 2001). The rules below are paraphrased summaries for scholarly use, with page numbers so each one can be checked against the book. No text or illustrations from the book are reproduced in this repository.

Enforcement key: **code** = done automatically by a helper, **audit** = flagged by `audit_vdqi()` (R) or `audit_figure()` (Python), **checklist** = Claude must verify by reading the figure.

## 1. Graphical excellence (p.13, p.51)

| # | Rule | Enforcement |
|---|------|-------------|
| 1.1 | Show the data; make the viewer think about substance, not method or design. | checklist |
| 1.2 | Give the most ideas in the shortest time with the least ink in the smallest space. | code (theme) |
| 1.3 | Present many numbers in a small space and make large data sets coherent. | checklist |
| 1.4 | Encourage comparison between pieces of data. | code (shared scales, sorted order) |
| 1.5 | Reveal data at several levels, from overview to fine structure (three viewing depths, p.155). | checklist |
| 1.6 | Serve a clear purpose: description, exploration, tabulation or decoration. | checklist |
| 1.7 | Integrate the graphic with its statistical and verbal description. | code (title states the finding) |

## 2. Graphical integrity (Chapter 2, p.53-77)

| # | Rule | Enforcement |
|---|------|-------------|
| 2.1 | Physical size on the graphic must be directly proportional to the number shown. Bars and areas therefore start at zero. | code (`vdqi_bar`, `bar`) + audit |
| 2.2 | Lie Factor = effect shown / effect in data; outside 0.95 to 1.05 is substantial distortion (p.57). | code (`lie_factor`) |
| 2.3 | Label clearly, thoroughly and directly; write explanations and label important events on the graphic. | code (direct labels) + audit (missing labels) |
| 2.4 | Show data variation, not design variation: regular scale intervals, no mid-axis changes (p.60-61). | checklist |
| 2.5 | Money over time: use deflated, standardized (e.g. per capita, constant-dollar) units (p.65-68). | code (`deflate`) |
| 2.6 | Do not use more varying dimensions than the data have: no area or volume for 1-D data, no 3-D effects (p.69-71). | audit (3-D, pie) + checklist |
| 2.7 | Never quote data out of context; always ask "compared to what?" (p.74). | checklist |

## 3. Data-ink (Chapter 4, p.91-105)

| # | Rule | Enforcement |
|---|------|-------------|
| 3.1 | Above all else show the data. | checklist |
| 3.2 | Maximize the data-ink ratio, within reason (p.96). | code (theme) |
| 3.3 | Erase non-data-ink, within reason: frames, backgrounds, heavy axes. | code (theme) + audit (shaded background) |
| 3.4 | Erase redundant data-ink (e.g. a number printed on top of a bar that already shows it, bilateral symmetry). | checklist |
| 3.5 | Revise and edit. | workflow step 6 |

## 4. Chartjunk (Chapter 5, p.107-121)

| # | Rule | Enforcement |
|---|------|-------------|
| 4.1 | No cross-hatching or patterns that vibrate (moire); use gray tints and word labels (p.107-111). | audit (hatching) |
| 4.2 | No dark grid; if a grid is needed, make it thin and light gray (p.112-116). | code (no grid) + audit |
| 4.3 | No "ducks": decoration, fake perspective, 3-D (p.116-121). | audit + checklist |

## 5. Redesigns derived from data-ink maximization (Chapter 6, p.123-137)

| # | Design | Helper |
|---|--------|--------|
| 5.1 | Quartile plot: whiskers min to Q1 and Q3 to max, median as a dot, gap for the middle half (p.123-125). | `vdqi_quartile`, `quartile_plot` |
| 5.2 | Bar chart without frame or y-axis line; white grid lines cut through the bars instead of ticks (p.126-129). | `vdqi_bar`, `bar` |
| 5.3 | Range-frame: axis lines run only from the data minimum to maximum (p.130-132). | `range_frame`, `vdqi_scatter`, `scatter` |
| 5.4 | Dot-dash plot / rug: marginal distributions on the frame (p.133-135). | ggplot2 `geom_rug()` if useful |

## 6. Multifunctioning elements and color (Chapter 7, p.139-159)

| # | Rule | Enforcement |
|---|------|-------------|
| 6.1 | Let the same ink do several jobs (data-based labels and grids). | checklist |
| 6.2 | Avoid graphical puzzles that must be decoded verbally (p.153). | checklist |
| 6.3 | Color has no natural order; use shades of gray for ordered quantities (p.154). | code (grays + one accent) |

## 7. Data density and small multiples (Chapter 8, p.161-175)

| # | Rule | Enforcement |
|---|------|-------------|
| 7.1 | Maximize data density within reason; most graphics can be shrunk to half size with no loss (Shrink Principle, p.169). | code (compact default size) |
| 7.2 | Small multiples: same design, same scales, indexed by one variable (p.170-175). | `vdqi_small_multiples`, `small_multiples` |

## 8. Aesthetics and technique (Chapter 9, p.177-191)

| # | Rule | Enforcement |
|---|------|-------------|
| 8.1 | Two or three numbers: write a sentence. Exact values or many localized comparisons: use a table. Order rows by content or value, not alphabetically (p.178-179). | workflow step 2 |
| 8.2 | Never use pie charts; a table is nearly always better (p.178). | audit |
| 8.3 | Words and pictures belong together: label outliers and events on the plot; integrate caption and legend (p.180). | code |
| 8.4 | Friendly graphic: words spelled out, read left to right, no legend required, serif upper-and-lower-case type, no red/green for essential contrasts (p.183). | code (theme, horizontal y label, direct labels, blue accent) + audit (legend) |
| 8.5 | Thin lines; data lines heavier than structural lines (p.185-186). | code |
| 8.6 | Shape: follow the data's natural shape; otherwise about 50% wider than tall (p.186-190). | code (default 1.5:1) + audit |
| 8.7 | Principles are guides, not dogma; it is better to break a rule than to make an ugly graphic (p.191). | judgement |

## Pre-delivery checklist (Claude runs this on every figure)

1. The title states the finding, not the chart type.
2. Every number on the graphic is proportional to the quantity shown (bars start at zero; no area for 1-D data).
3. Context is present: a comparison group, a baseline period, or a reference line.
4. Money over time is in constant (and, if relevant, per capita) units, and the units are stated.
5. Scales are regular and identical across panels being compared.
6. No legend if direct labels can do the job; no abbreviations a reader must decode.
7. No 3-D, shadows, hatching, dark grids, background shading or decorative images.
8. Colors: grays plus at most one or two accents; never red versus green for an essential contrast.
9. Outliers or key events are labeled on the plot, with non-identifying names only.
10. Wider than tall unless the data say otherwise; type is legible at final print size.
11. The audit function returns no issues, or each remaining issue is justified in one line.
