"""Run with:  python -m pytest -q tests/"""
import sys
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "python"))
import inksight as ink  # noqa: E402


def test_lie_factor_matches_book_example():
    # Fuel-economy chart (p.57): lines 0.6 -> 5.3 in, data 18.0 -> 27.5 mpg, LF about 14.8
    lf, distorted = ink.lie_factor(0.6, 5.3, 18.0, 27.5)
    assert round(lf, 1) == 14.8
    assert distorted


def test_lie_factor_honest():
    lf, distorted = ink.lie_factor(10, 20, 5, 10)
    assert lf == pytest.approx(1.0) and not distorted


def test_deflate_constant_and_per_capita():
    real = ink.deflate([100, 200], [1.0, 2.0])
    assert np.allclose(real, [100, 100])
    assert np.allclose(ink.deflate([100, 200], [1.0, 2.0], population=[10, 20]), [10, 5])


def test_audit_flags_pie_legend_and_tall_figure():
    fig, ax = plt.subplots(figsize=(4, 6))
    ax.pie([1, 2, 3], labels=list("abc"))
    ax.legend()
    issues = " ".join(ink.audit_figure(fig))
    assert "Pie" in issues and "Legend" in issues and "taller" in issues
    plt.close(fig)


def test_audit_flags_truncated_bars_and_hatching():
    fig, ax = plt.subplots(figsize=ink.DEFAULT_SIZE)
    ax.bar(["a", "b"], [50, 55], hatch="//")
    ax.set_ylim(45, 56)
    ax.set_ylabel("y")
    issues = " ".join(ink.audit_figure(fig))
    assert "zero" in issues and "Hatching" in issues
    plt.close(fig)


def test_helpers_produce_clean_audit(tmp_path):
    rng = np.random.default_rng(1)
    with ink.vdqi_style():
        fig, axes = plt.subplots(1, 3, figsize=(12, 4))
        ink.bar(["A", "B", "C"], [3, 9, 5], ylabel="Count", ax=axes[0])
        x = rng.normal(size=40)
        ink.scatter(x, 2 * x + rng.normal(size=40), xlabel="x", ylabel="y", ax=axes[1])
        ink.quartile_plot({"g1": rng.normal(size=30), "g2": rng.normal(1, size=30)},
                         ylabel="Value", ax=axes[2])
        assert ink.audit_figure(fig) == []
        out = tmp_path / "fig.png"
        ink.save_figure(fig, out)
        assert out.exists()
        with pytest.raises(FileExistsError):
            ink.save_figure(fig, out)
    plt.close(fig)


def test_saved_files_have_no_software_metadata(tmp_path):
    fig, ax = plt.subplots(figsize=ink.DEFAULT_SIZE)
    ax.plot([0, 1], [0, 1])
    ax.set_xlabel("x")
    png, pdf = tmp_path / "a.png", tmp_path / "a.pdf"
    ink.save_figure(fig, png)
    ink.save_figure(fig, pdf)
    assert b"matplotlib" not in png.read_bytes().lower()
    assert b"matplotlib" not in pdf.read_bytes().lower()
    plt.close(fig)


def test_save_rejects_bad_paths(tmp_path):
    fig, _ = plt.subplots()
    with pytest.raises(ValueError):
        ink.save_figure(fig, tmp_path / "a.exe")
    with pytest.raises(ValueError):
        ink.save_figure(fig, "../escape.png")
    plt.close(fig)
