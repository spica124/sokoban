"""build_tiers.py RATED_JSON - assemble levels/{easy,normal,hard,expert}.txt.

Sources
  levels/src/easy_custom.txt   24 hand-made intro levels (kept first in Easy)
  levels/src/sc_ordered.txt    StarCraft "Sokoban 1.00" 24 stages + 12 bonus (kept first in Hard)
  levels/src/hard_custom.txt   23 hand-made depot puzzles (Hard)
  RATED_JSON                   Boxoban levels rated by tools/rate_boxoban.py (Apache-2.0)

Difficulty score (used to rank Boxoban levels and fill each tier):
  score = 1.5*log10(states) + 0.12*pushes + 0.01*moves
Each tier gets ~TARGET levels, ordered easiest -> hardest within the tier
(except the StarCraft stages, which keep their original order).
"""
import json
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from validate_levels import parse

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "levels" / "src"
TARGET = 200


def score(par, pushes, states):
    return 1.5 * math.log10(max(states, 1)) + 0.12 * pushes + 0.01 * par


def load_src(name):
    out = []
    for lv in parse((SRC / name).read_text(encoding="utf-8")):
        meta = dict(lv["meta"])
        out.append({"name": meta.get("name", ""), "name_en": meta.get("name_en", ""),
                    "par": int(meta.get("par", 0)), "solution": meta.get("solution", ""),
                    "rows": lv["rows"], "src": name})
    return out


def norm(rows):
    """Canonical key for de-duplication: strip empty border rows/cols."""
    return "\n".join(r.rstrip() for r in rows)


def trim(rows):
    """Boxoban levels are padded 10x10; drop outer rows/cols that are pure wall
    when the next row/col inward is also pure wall (one wall ring is kept)."""
    rows = [r.rstrip() for r in rows]
    w = max(len(r) for r in rows)
    rows = [r.ljust(w) for r in rows]
    pure = lambda r: set(r) == {"#"}
    while len(rows) > 2 and pure(rows[0]) and pure(rows[1]):
        rows = rows[1:]
    while len(rows) > 2 and pure(rows[-1]) and pure(rows[-2]):
        rows = rows[:-1]
    col = lambda i: "".join(r[i] for r in rows)
    while w > 2 and pure(col(0)) and pure(col(1)):
        rows = [r[1:] for r in rows]; w -= 1
    while w > 2 and pure(col(w - 1)) and pure(col(w - 2)):
        rows = [r[:-1] for r in rows]; w -= 1
    return rows


def replay_ok(rows, solution):
    """Replay a solution string; True when every box ends on a goal."""
    from validate_levels import build, DIRS
    walls, goals, boxes, player = build(rows)
    boxes = set(boxes)
    for d in solution:
        dx, dy = DIRS[d]
        nxt = (player[0] + dx, player[1] + dy)
        if nxt in walls:
            return False
        if nxt in boxes:
            beyond = (nxt[0] + dx, nxt[1] + dy)
            if beyond in walls or beyond in boxes:
                return False
            boxes.remove(nxt); boxes.add(beyond)
        player = nxt
    return boxes == goals


def write_tier(path, levels):
    blocks = []
    for lv in levels:
        meta = []
        if lv.get("name"):
            meta.append(("name", lv["name"]))
        if lv.get("name_en"):
            meta.append(("name_en", lv["name_en"]))
        if lv.get("src"):
            meta.append(("source", lv["src"]))
        meta += [("par", str(lv["par"])), ("solution", lv["solution"])]
        blocks.append("\n".join(f"; {k}: {v}" for k, v in meta) + "\n" + "\n".join(lv["rows"]))
    path.write_text("\n\n".join(blocks) + "\n", encoding="utf-8")
    print(f"{path.name}: {len(levels)} levels")


def main():
    rated = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
    seen = set()
    box = []
    for r in rated:
        key = norm(r["rows"])
        if key in seen:
            continue
        seen.add(key)
        r["score"] = score(r["par"], r["pushes"], r["states"])
        r["src"] = "boxoban/" + r["source"]
        r["rows"] = trim(list(r["rows"]))
        box.append(r)
    box.sort(key=lambda r: r["score"])
    n = len(box)
    print(f"{n} unique boxoban levels; score range {box[0]['score']:.1f}..{box[-1]['score']:.1f}")

    easy_custom = load_src("easy_custom.txt")
    hard_custom = load_src("hard_custom.txt")
    sc = load_src("sc_ordered.txt")

    # Slice the single sorted list into bands so the tiers are clearly separated:
    #   easy   : bottom of the list            (after the 24 intro levels)
    #   normal : 30th-34th percentile band
    #   hard   : 72nd-75th percentile band      (after StarCraft + depot puzzles)
    #   expert : top 4%
    easy = easy_custom + box[: TARGET - len(easy_custom)]
    lo = int(n * 0.30)
    normal = box[lo: lo + TARGET]
    fill = TARGET - len(sc) - len(hard_custom)
    lo = int(n * 0.72)
    hard_fill = box[lo: lo + fill]
    hard = sc + sorted(hard_custom + hard_fill, key=lambda r: r.get("score", 9.0))
    expert = box[n - TARGET:]

    for name, lst in (("easy", easy), ("normal", normal), ("hard", hard), ("expert", expert)):
        bad = [i for i, r in enumerate(lst) if not replay_ok(r["rows"], r["solution"])]
        assert not bad, (name, bad[:5])
    out = ROOT / "levels"
    write_tier(out / "easy.txt", easy)
    write_tier(out / "normal.txt", normal)
    write_tier(out / "hard.txt", hard)
    write_tier(out / "expert.txt", expert)
    for name, lst in (("easy", easy), ("normal", normal), ("hard", hard), ("expert", expert)):
        sc_ = [r["score"] for r in lst if "score" in r]
        if sc_:
            print(f"  {name}: boxoban score {min(sc_):.1f}..{max(sc_):.1f}, pushes {min(r['pushes'] for r in lst if 'pushes' in r)}..{max(r['pushes'] for r in lst if 'pushes' in r)}")


if __name__ == "__main__":
    main()
