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


def read_log(config_name: str) -> dict:
    """Read the logs from the longer runs."""
    sypd = []
    wall_time_s = None
    steps = None
    fpath = f".calkit/slurm/logs/{config_name}.out"
    if not os.path.isfile(fpath):
        print(f"Log file {fpath} not found.")
        return {}
    with open(fpath, "r") as f:
        for line in f:
            if "estimated_sypd = " in line:
                try:
                    parts = line.strip().split()
                    sypd_value = float(parts[-1].replace('"', ""))
                    sypd.append(sypd_value)
                except ValueError:
                    continue
            if "Info: Ran step!" in line:
                try:
                    parts = line.strip().split()
                    wall_time_s = float(parts[7])
                    steps = int(parts[4])
                except ValueError:
                    continue
    return {
        "long_sypd": sypd[-1] if sypd else None,
        "long_wall_time_s": wall_time_s,
        "long_steps": steps,
    }


sqlite_fpaths = sorted(glob.glob("results/nsys/*.sqlite"))
results = []

for fpath in sqlite_fpaths:
    config = os.path.basename(fpath).removesuffix(".sqlite")
    print(f"Processing {config} from {fpath}")
    try:
        summary = {"case": config} | get_summary(fpath) | read_log(config)
        results.append(summary)
    except Exception as e:
        print(f"Failed to process {config}: {e}")

df = pl.DataFrame(results)
print(df)

# Print values normalized by baseline-const case
baseline = df.filter(pl.col("case") == "baseline-const").row(0, named=True)
df_normalized = df.with_columns(
    [
        (pl.col(col) / baseline[col]).alias(col)
        for col in df.select(pl.exclude("case")).columns
    ]
)
print("Normalized by baseline:\n", df_normalized)

df.write_csv("results/summary.csv")
