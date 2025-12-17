"""Extract a summary from an nsys report file."""

import glob
import os
import sqlite3

import polars as pl


def get_summary(fpath_in) -> dict:
    """Extract summary from nsys SQLite report file."""
    conn = sqlite3.connect(fpath_in)
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM ANALYSIS_DETAILS")
    row = cursor.fetchone()
    columns = [description[0] for description in cursor.description]
    summary = dict(zip(columns, row))
    summary["duration_s"] = summary["duration"] / 1e9  # Convert from ns to s
    conn.close()
    return summary


sqlite_fpaths = sorted(glob.glob("results/nsys/*.sqlite"))
results = []

for fpath in sqlite_fpaths:
    config = os.path.basename(fpath).removesuffix(".sqlite")
    print(f"Processing {config} from {fpath}")
    try:
        summary = {"case": config} | get_summary(fpath)
        results.append(summary)
    except Exception as e:
        print(f"Failed to process {config}: {e}")

df = pl.DataFrame(results)
print(df)
df.write_csv("results/summary.csv")
