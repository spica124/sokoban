"""validate_parallel.py [FILE] [--check] [--procs N] [--limit N]
Same as validate_levels.py but solves every level in parallel processes and
keeps the file order. Writes par/solution back unless --check is given."""
import argparse
import sys, time
from multiprocessing import Pool
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from validate_levels import DEFAULT_FILE, parse, solve, count_pushes


def work(args):
    rows, limit = args
    stats = {}
    t = time.time()
    sol, err = solve(rows, limit=limit, stats=stats)
    return sol, err, stats.get("explored", 0), time.time() - t


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("file", nargs="?", default=str(DEFAULT_FILE))
    ap.add_argument("--check", action="store_true")
    ap.add_argument("--procs", type=int, default=6)
    ap.add_argument("--limit", type=int, default=3_000_000)
    a = ap.parse_args()
    check_only, procs, limit = a.check, a.procs, a.limit
    file = Path(a.file)
    levels = parse(file.read_text(encoding="utf-8"))
    with Pool(procs) as pool:
        results = pool.map(work, [(lv["rows"], limit) for lv in levels], chunksize=1)
    ok = True
    out = []
    for i, (lv, (sol, err, explored, secs)) in enumerate(zip(levels, results)):
        meta = dict(lv["meta"])
        name = meta.get("name_en") or meta.get("name", f"#{i+1}")
        boxes = sum(r.count("$") + r.count("*") for r in lv["rows"])
        if sol is None:
            ok = False
            print(f"[{i+1:2d}] {name}: FAIL - {err} ({secs:.0f}s)")
        else:
            print(f"[{i+1:2d}] {name}: ok boxes={boxes} pushes={count_pushes(lv['rows'], sol)} par={len(sol)} states={explored} ({secs:.0f}s)")
        if sol is not None:
            kept = [(k, v) for k, v in lv["meta"] if k not in ("par", "solution")]
            kept += [("par", str(len(sol))), ("solution", sol)]
        else:
            kept = list(lv["meta"])   # keep the previous par/solution on failure
        out.append("\n".join(f"; {k}: {v}" for k, v in kept) + "\n" + "\n".join(lv["rows"]))
    if not check_only and ok:
        file.write_text("\n\n".join(out) + "\n", encoding="utf-8")
        print(f"{file.name} updated")
    elif not check_only:
        print("file NOT written: some levels failed")
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
