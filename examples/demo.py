"""Run from the repository root:  python examples/demo.py
All data below are simulated. No real or patient data are used."""
import sys
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "python"))
import inksight as ink  # noqa: E402

rng = np.random.default_rng(42)
out = Path("examples/output")
out.mkdir(parents=True, exist_ok=True)

with ink.vdqi_style():
    # Redesigned bar chart
    fig, ax = plt.subplots(figsize=ink.DEFAULT_SIZE)
    ink.bar(["Basal", "HER2", "LumA", "LumB", "Normal"], [98, 58, 231, 129, 40],
           ylabel="Tumours", title="Luminal A is the most common subtype", ax=ax)
    print("bar audit:", ink.save_figure(fig, out / "py_bar.png", overwrite=True))

    # Time-series with direct labels
    fig, ax = plt.subplots(figsize=ink.DEFAULT_SIZE)
    days = np.arange(22)
    series = {arm: (days, 100 + s * days + np.cumsum(rng.normal(0, 3, 22)))
              for arm, s in [("Vehicle", 9), ("Drug A", 6), ("Drug B", 5.5), ("Drug A + B", 2.5)]}
    ink.lines(series, xlabel="Day", ylabel="Tumour volume, cubic mm", highlight="Drug A + B",
             title="Combination therapy slows tumour growth most", ax=ax)
    print("lines audit:", ink.save_figure(fig, out / "py_lines.png", overwrite=True))

    # Small multiples
    panels = {f"Site {s}": (np.arange(1, 27), np.cumsum(rng.poisson(rng.uniform(1, 4), 26)))
              for s in range(1, 9)}
    fig, _ = ink.small_multiples(panels, ncols=4, xlabel="Week", ylabel="Enrolled")
    print("small multiples audit:", ink.save_figure(fig, out / "py_small_multiples.png", overwrite=True))

print("Lie Factor of the book's fuel-economy chart:", ink.lie_factor(0.6, 5.3, 18, 27.5))
