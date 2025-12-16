"""Extract a summary from an nsys report file."""

import sqlite3

import polars as pl


def get_summary(fpath_in) -> dict:
    """Extract summary from nsys report file."""
    conn = sqlite3.connect(fpath_in)
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM ANALYSIS_DETAILS")
    row = cursor.fetchone()
    columns = [description[0] for description in cursor.description]
    summary = dict(zip(columns, row))
    summary["duration_s"] = summary["duration"] / 1e9  # Convert from ns to s
    conn.close()
    return summary


configs = ["baseline", "mod", "baseline-const"]
results = []

for config in configs:
    fpath_in = f"results/nsys/{config}.sqlite"
    summary = {"case": config} | get_summary(fpath_in)
    results.append(summary)

df = pl.DataFrame(results)
df.write_csv("results/summary.csv")
