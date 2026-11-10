"""inksight.py (InkSight)

matplotlib helpers that apply the design rules in E. R. Tufte,
"The Visual Display of Quantitative Information" (2nd ed., 2001).
Page numbers in comments refer to that book. See references/principles.md.

Security and privacy notes
- Dependencies: numpy, matplotlib. No network calls, no subprocess, no eval,
  no pickle, no files read.
- Styling is applied through a context manager, so global rcParams are left
  untouched after use.
- save_figure() is the only function that writes to disk. It refuses to
  overwrite unless asked and strips software/date metadata from the file.
"""
from __future__ import annotations

import contextlib
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np

# Palette: grays carry a natural visual order (p.154); blue is the single
# accent because most colour-deficient viewers can distinguish it (p.183).
INK, MUTED, ACCENT = "#262626", "#A6A6A6", "#1F5FAD"

# Erase non-data-ink (p.96), serif upper-and-lower-case type (p.183),
# thin lines (p.185), no grid (p.112-116).
STYLE = {
    "font.family": "serif",
    "font.size": 10,
    "axes.spines.top": False,
    "axes.spines.right": False,
    "axes.linewidth": 0.4,
    "axes.edgecolor": INK,
    "axes.labelcolor": INK,
    "axes.grid": False,
    "axes.titlelocation": "left",
    "axes.titlesize": 11,
    "xtick.color": INK,
    "ytick.color": INK,
    "xtick.major.width": 0.3,
    "ytick.major.width": 0.3,
    "lines.linewidth": 1.0,
    "legend.frameon": False,
    "figure.facecolor": "white",
    "savefig.facecolor": "white",
}

DEFAULT_SIZE = (6.5, 6.5 / 1.5)  # about 1.5 times wider than tall (p.190)


@contextlib.contextmanager
def vdqi_style():
    """Apply the style only inside a `with` block."""
    with plt.rc_context(STYLE):
        yield


def _horizontal_ylabel(ax, text):
    """Words read left to right, not up the y-axis (p.183): the y label is
    written horizontally just above the top-left corner of the plot."""
    if text:
        ax.set_ylabel(text, rotation=0, ha="left", va="bottom")
        ax.yaxis.set_label_coords(0, 1.02)


def _title(ax, title):
    """Title sits above the horizontal y label, left aligned."""
    if title:
        ax.set_title(title, pad=18 if ax.get_ylabel() else 6)


def range_frame(ax, x, y):
    """Axis lines span only the data range, so the frame reports min/max (p.130-132)."""
    x, y = np.asarray(x, float), np.asarray(y, float)
    ax.spines["bottom"].set_bounds(np.nanmin(x), np.nanmax(x))
    ax.spines["left"].set_bounds(np.nanmin(y), np.nanmax(y))
    return ax


def scatter(x, y, labels=None, xlabel="", ylabel="", title=None, ax=None):
    """Scatterplot with range-frame (p.130-133). `labels` is an optional
    sequence of strings or None used to name outliers directly (p.180).
    Never pass patient identifiers as labels."""
    ax = ax or plt.gca()
    ax.plot(x, y, "o", ms=3, color=INK, ls="none")
    range_frame(ax, x, y)
    if labels is not None:
        for xi, yi, lab in zip(x, y, labels):
            if lab:
                ax.annotate(str(lab), (xi, yi), xytext=(4, 0),
                            textcoords="offset points", va="center", fontsize=8)
    ax.set_xlabel(xlabel)
    _horizontal_ylabel(ax, ylabel)
    _title(ax, title)
    return ax


def lines(series, xlabel="", ylabel="", title=None, highlight=None, ax=None):
    """Time-series with each line named at its right end, no legend (p.28-39, p.183).
    `series` maps name -> (x, y). `highlight` is a name or list of names drawn in blue."""
    ax = ax or plt.gca()
    hl = {highlight} if isinstance(highlight, str) else set(highlight or [])
    for name, (x, y) in series.items():
        color = INK if not hl else (ACCENT if name in hl else MUTED)
        ax.plot(x, y, color=color, lw=1.0)
        ax.annotate(str(name), (x[-1], y[-1]), xytext=(4, 0),
                    textcoords="offset points", va="center", color=color, fontsize=9)
    ax.margins(x=0.12)
    ax.set_xlabel(xlabel)
    _horizontal_ylabel(ax, ylabel)
    _title(ax, title)
    return ax


def bar(categories, values, ylabel="", title=None, ax=None):
    """Redesigned bar chart (p.126-129): starts at zero, sorted by value (p.178),
    no frame, no y-axis line, white grid lines through the bars instead of ticks."""
    values = np.asarray(values, float)
    if np.any(values < 0):
        raise ValueError("bar() expects non-negative values")
    order = np.argsort(-values)
    cats = [str(categories[i]) for i in order]
    vals = values[order]
    ax = ax or plt.gca()
    ax.bar(cats, vals, width=0.5, color=MUTED)
    ax.set_ylim(0, vals.max() * 1.05)
    ticks = [t for t in ax.get_yticks() if 0 < t < vals.max()]
    for t in ticks:
        ax.axhline(t, color="white", lw=0.8)
    ax.set_yticks(ticks)
    ax.spines["left"].set_visible(False)
    ax.tick_params(axis="both", length=0)
    _horizontal_ylabel(ax, ylabel)
    _title(ax, title)
    return ax


def quartile_plot(groups, xlabel="", ylabel="", title=None, ax=None):
    """Tufte's quartile plot (p.123-125): line min->Q1, gap for the middle half,
    dot at the median, line Q3->max. `groups` maps name -> 1-D values."""
    ax = ax or plt.gca()
    for i, (name, v) in enumerate(groups.items()):
        mn, q1, md, q3, mx = np.nanpercentile(np.asarray(v, float), [0, 25, 50, 75, 100])
        ax.plot([i, i], [mn, q1], color=INK, lw=0.8)
        ax.plot([i, i], [q3, mx], color=INK, lw=0.8)
        ax.plot(i, md, "o", ms=3.5, color=INK)
    ax.set_xticks(range(len(groups)), [str(k) for k in groups])
    ax.spines["bottom"].set_visible(False)
    ax.tick_params(axis="x", length=0)
    ax.set_xlabel(xlabel)
    _horizontal_ylabel(ax, ylabel)
    _title(ax, title)
    return ax


def small_multiples(panels, ncols=4, panel_size=(1.6, 1.1), xlabel="", ylabel=""):
    """Same design repeated with shared scales (p.168-175).
    `panels` maps title -> (x, y). Returns (fig, axes)."""
    n = len(panels)
    nrows = int(np.ceil(n / ncols))
    fig, axes = plt.subplots(nrows, ncols, sharex=True, sharey=True,
                             figsize=(panel_size[0] * ncols, panel_size[1] * nrows),
                             squeeze=False)
    for ax, (name, (x, y)) in zip(axes.flat, panels.items()):
        ax.plot(x, y, color=INK, lw=0.7)
        ax.set_title(str(name), fontsize=8, loc="left")
        ax.tick_params(labelsize=7)
    for ax in axes.flat[n:]:
        ax.set_visible(False)
    fig.supxlabel(xlabel, fontsize=8)
    fig.supylabel(ylabel, fontsize=8)
    return fig, axes


# ---- Integrity calculations -------------------------------------------------
def lie_factor(shown_start, shown_end, data_start, data_end):
    """Lie Factor = size of effect shown / size of effect in data (p.57).
    Returns (value, distorted) where distorted means outside 0.95-1.05."""
    if shown_start == 0 or data_start == 0 or data_end == data_start:
        raise ValueError("start values must be non-zero and the data must change")
    lf = ((shown_end - shown_start) / shown_start) / ((data_end - data_start) / data_start)
    return lf, not (0.95 <= lf <= 1.05)


def deflate(values, price_index, base=None, population=None):
    """Convert nominal money to constant units, optionally per capita (p.65-68)."""
    values, price_index = np.asarray(values, float), np.asarray(price_index, float)
    if values.shape != price_index.shape or np.any(price_index <= 0):
        raise ValueError("values and a positive price_index must have the same length")
    base = price_index[0] if base is None else base
    real = values * base / price_index
    if population is not None:
        population = np.asarray(population, float)
        if population.shape != values.shape or np.any(population <= 0):
            raise ValueError("population must be positive and match values")
        real = real / population
    return real


# ---- Audit -----------------------------------------------------------------
def audit_figure(fig):
    """Return a list of rule violations found mechanically (empty = none found).
    The checklist in references/principles.md covers what code cannot see."""
    from matplotlib.patches import Rectangle, Wedge

    issues = []
    w, h = fig.get_size_inches()
    if w < h:
        issues.append("Figure is taller than wide: prefer about 1.5:1 unless the data suggest otherwise (p.190).")
    for ax in fig.get_axes():
        if not ax.get_visible():
            continue
        if ax.name == "3d":
            issues.append("3-D axes: use no more varying dimensions than the data have (p.71, p.118).")
        if ax.name == "polar" or any(isinstance(p, Wedge) for p in ax.patches):
            issues.append("Pie/polar chart: use a sorted bar chart or a table instead (p.178).")
        bars = [p for p in ax.patches if isinstance(p, Rectangle) and p.get_height() != 0]
        if bars:
            lo, hi = ax.get_ylim()
            if lo > 0 or hi < 0:
                issues.append("Bars do not start at zero: lengths are no longer proportional (p.56, p.77).")
            if any(p.get_hatch() for p in bars):
                issues.append("Hatching creates moire vibration: use gray tints and direct labels (p.107-111).")
        if ax.get_legend() is not None:
            issues.append("Legend shown: label the data directly on the plot where possible (p.183).")
        gridlines = [g for g in ax.get_xgridlines() + ax.get_ygridlines() if g.get_visible()]
        if any(np.mean(_rgb(g.get_color())) < 0.8 for g in gridlines):
            issues.append("Dark grid lines: mute to light gray or remove (p.112-116).")
        titled = any(ax.get_title(loc=l) for l in ("left", "center", "right"))
        if not ax.get_xlabel() and not ax.get_ylabel() and not titled:
            issues.append("Axes lack labels or title: label clearly and thoroughly (p.77).")
    return sorted(set(issues))


def _rgb(color):
    from matplotlib.colors import to_rgb
    return to_rgb(color)


# ---- Save ------------------------------------------------------------------
_ALLOWED = {".pdf", ".png", ".svg", ".tiff"}


def save_figure(fig, path, dpi=300, overwrite=False, audit=True):
    """Save with metadata stripped. Vector PDF/SVG for print, PNG at 300 dpi.
    Refuses to overwrite unless overwrite=True. Returns the audit findings."""
    path = Path(path)
    if path.suffix.lower() not in _ALLOWED:
        raise ValueError(f"Use one of {sorted(_ALLOWED)}")
    if ".." in path.parts:
        raise ValueError("Relative '..' paths are not allowed")
    if path.exists() and not overwrite:
        raise FileExistsError(f"{path} exists; pass overwrite=True to replace it")
    findings = audit_figure(fig) if audit else []
    meta = {
        ".pdf": {"Creator": None, "Producer": None, "CreationDate": None},
        ".png": {"Software": None},
        ".svg": {"Creator": None, "Date": None, "Format": None, "Type": None},
        ".tiff": None,
    }[path.suffix.lower()]
    kwargs = {"metadata": meta} if meta is not None else {}
    fig.savefig(path, dpi=dpi, bbox_inches="tight", **kwargs)
    return findings
