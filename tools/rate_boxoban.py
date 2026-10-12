"""rate_boxoban.py IN_DIR OUT_JSON [--procs N] [--limit N]
Solve every Boxoban level file (google-deepmind/boxoban-levels format:
blocks headed by "; N") in IN_DIR and write difficulty metrics to OUT_JSON:
  [{"source": file, "idx": n, "rows": [...], "par": moves, "pushes": p,
    "states": explored, "boxes": b, "solution": "..."}]
Unsolved levels (search limit) are dropped."""
import argparse
import json
import sys
import time
from multiprocessing import Pool
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from validate_levels import solve, count_pushes


def parse_boxoban(text):
    levels, rows, idx = [], [], None
    for line in text.splitlines():
        line = line.rstrip("\r")
        if line.startswith(";"):
            if rows:
                levels.append((idx, rows))
            rows, idx = [], int(line[1:].strip() or 0)
        elif line.strip():
            rows.append(line)
    if rows:
        levels.append((idx, rows))
    return levels


def work(job):
    source, idx, rows, limit = job
    stats = {}
    sol, err = solve(rows, limit=limit, stats=stats)
    if sol is None:
        return None
    return {"source": source, "idx": idx, "rows": rows, "par": len(sol),
            "pushes": count_pushes(rows, sol), "states": stats.get("explored", 0),
            "boxes": sum(r.count("$") + r.count("*") for r in rows), "solution": sol}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("in_dir")
    ap.add_argument("out_json")
    ap.add_argument("--procs", type=int, default=8)
    ap.add_argument("--limit", type=int, default=400_000)
    a = ap.parse_args()
    jobs = []
    for f in sorted(Path(a.in_dir).glob("*.txt")):
        for idx, rows in parse_boxoban(f.read_text(encoding="utf-8")):
            jobs.append((f.stem, idx, rows, a.limit))
    print(f"{len(jobs)} levels, {a.procs} processes", flush=True)
    t = time.time()
    out = []
    with Pool(a.procs) as pool:
        for i, r in enumerate(pool.imap_unordered(work, jobs, chunksize=4)):
            if r:
                out.append(r)
            if (i + 1) % 250 == 0:
                print(f"{i + 1}/{len(jobs)} done, {len(out)} solved, {time.time() - t:.0f}s", flush=True)
    Path(a.out_json).write_text(json.dumps(out), encoding="utf-8")
    print(f"wrote {len(out)} rated levels to {a.out_json} in {time.time() - t:.0f}s")


if __name__ == "__main__":
    main()
