"""variants.py - rule-variant sokoban: shared rules, solver and level generators.

Rules (must match scripts/Board.gd exactly):
  color   : boxes and goals carry a color (0 or 1). Solved when every box sits
            on a goal of its own color.
  ice     : when a pushed box lands on an ice cell it keeps sliding in the push
            direction while the next cell is enterable floor without a box.
            It stops on the first non-ice cell or when blocked. Players never slide.
  oneway  : an arrow cell can only be entered moving in the arrow direction
            (applies to the player and to boxes, including sliding boxes).

Level meta (coordinates are in the level's own rows, 0-based x,y):
  ; rules: color,ice
  ; boxcolor: x,y,1;x,y,1      (boxes not listed are color 0)
  ; goalcolor: x,y,1;...
  ; ice: x,y;x,y
  ; oneway: x,y,R;x,y,U

Usage:
  python tools/variants.py build      generate levels/rule_*.txt and levels/daily.txt
  python tools/variants.py check FILE  re-solve every level in FILE and compare par
"""
import json
import math
import random
import sys
from collections import deque
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(Path(__file__).resolve().parent))
from validate_levels import parse  # noqa: E402

DIRS = {"U": (0, -1), "D": (0, 1), "L": (-1, 0), "R": (1, 0)}


# ======================================================================= level
class Lv:
    def __init__(self, rows, meta=None):
        meta = dict(meta or [])
        self.rows = [r for r in rows]
        self.walls, self.goals, self.boxes = set(), {}, {}
        self.player = None
        for y, row in enumerate(rows):
            for x, c in enumerate(row):
                p = (x, y)
                if c == "#":
                    self.walls.add(p)
                elif c == "@":
                    self.player = p
                elif c == "+":
                    self.player = p
                    self.goals[p] = 0
                elif c == "$":
                    self.boxes[p] = 0
                elif c == "*":
                    self.boxes[p] = 0
                    self.goals[p] = 0
                elif c == ".":
                    self.goals[p] = 0
        self.w = max(len(r) for r in rows)
        self.h = len(rows)
        # one-cell wall border like Board.gd, so open edges never leak
        self.floor = self._flood()
        for p, c in _cells(meta.get("boxcolor", "")):
            self.boxes[p] = c
        for p, c in _cells(meta.get("goalcolor", "")):
            self.goals[p] = c
        self.ice = {p for p, _ in _cells(meta.get("ice", ""), with_value=False)}
        self.arrows = {p: d for p, d in _cells(meta.get("oneway", ""), as_dir=True)}
        self.rules = [r for r in meta.get("rules", "").split(",") if r]

    def _flood(self):
        seen = {self.player}
        stack = [self.player]
        while stack:
            x, y = stack.pop()
            for dx, dy in DIRS.values():
                n = (x + dx, y + dy)
                if 0 <= n[0] < self.w and 0 <= n[1] < self.h and n not in self.walls and n not in seen:
                    seen.add(n)
                    stack.append(n)
        return seen

    # ---- rule helpers ------------------------------------------------------
    def can_enter(self, cell, d):
        a = self.arrows.get(cell)
        return a is None or a == d

    def slide_target(self, boxes, b, d):
        """Final cell of box b pushed in d (b already removed from boxes), or None."""
        dx, dy = DIRS[d]
        t = (b[0] + dx, b[1] + dy)
        if t not in self.floor or t in boxes or not self.can_enter(t, d):
            return None
        cur = t
        while cur in self.ice:
            n = (cur[0] + dx, cur[1] + dy)
            if n in self.floor and n not in boxes and self.can_enter(n, d):
                cur = n
            else:
                break
        return cur

    def is_solved(self, boxes):
        return all(self.goals.get(p, -1) == c for p, c in boxes.items())

    def meta_lines(self):
        out = []
        if self.rules:
            out.append(("rules", ",".join(self.rules)))
        bc = [f"{x},{y},{c}" for (x, y), c in sorted(self.boxes.items()) if c]
        gc = [f"{x},{y},{c}" for (x, y), c in sorted(self.goals.items()) if c]
        if bc:
            out.append(("boxcolor", ";".join(bc)))
        if gc:
            out.append(("goalcolor", ";".join(gc)))
        if self.ice:
            out.append(("ice", ";".join(f"{x},{y}" for x, y in sorted(self.ice))))
        if self.arrows:
            out.append(("oneway", ";".join(f"{x},{y},{d}" for (x, y), d in sorted(self.arrows.items()))))
        return out


def _cells(text, with_value=True, as_dir=False):
    out = []
    for part in text.split(";"):
        part = part.strip()
        if not part:
            continue
        bits = part.split(",")
        p = (int(bits[0]), int(bits[1]))
        if as_dir:
            out.append((p, bits[2]))
        elif with_value:
            out.append((p, int(bits[2]) if len(bits) > 2 else 1))
        else:
            out.append((p, None))
    return out


# ======================================================================= replay
def replay(lv, solution, count_slides=False):
    """Simulate the move string with the exact Board.gd rules.
    Returns (solved, pushes, slides) or (False, ...) if a move is illegal."""
    player = lv.player
    boxes = dict(lv.boxes)
    pushes = slides = 0
    for d in solution:
        dx, dy = DIRS[d]
        t = (player[0] + dx, player[1] + dy)
        if t not in lv.floor or not lv.can_enter(t, d):
            return False, pushes, slides
        if t in boxes:
            c = boxes.pop(t)
            f = lv.slide_target(boxes, t, d)
            if f is None:
                return False, pushes, slides
            boxes[f] = c
            pushes += 1
            first = (t[0] + dx, t[1] + dy)
            if f != first:
                slides += 1
        player = t
    return lv.is_solved(boxes), pushes, slides


# ======================================================================= solver
def _reach(lv, start, boxes):
    seen = {start}
    stack = [start]
    while stack:
        cur = stack.pop()
        for d, (dx, dy) in DIRS.items():
            n = (cur[0] + dx, cur[1] + dy)
            if n in lv.floor and n not in boxes and n not in seen and lv.can_enter(n, d):
                seen.add(n)
                stack.append(n)
    return seen


def _path(lv, start, goal, boxes):
    if start == goal:
        return ""
    prev = {start: None}
    q = deque([start])
    while q:
        cur = q.popleft()
        for d, (dx, dy) in DIRS.items():
            n = (cur[0] + dx, cur[1] + dy)
            if n in lv.floor and n not in boxes and n not in prev and lv.can_enter(n, d):
                prev[n] = (cur, d)
                if n == goal:
                    out = []
                    while prev[n] is not None:
                        n, dd = prev[n]
                        out.append(dd)
                    return "".join(reversed(out))
                q.append(n)
    return None


def _corner_dead(lv, p, color):
    if lv.goals.get(p, -1) == color:
        return False
    x, y = p
    up = (x, y - 1) not in lv.floor
    down = (x, y + 1) not in lv.floor
    left = (x - 1, y) not in lv.floor
    right = (x + 1, y) not in lv.floor
    return (up or down) and (left or right)


def solve(lv, limit=400_000, stats=None):
    """Push-optimal BFS. Returns move string or None."""
    if lv.player is None:
        return None
    colors_b = sorted(lv.boxes.values())
    colors_g = sorted(lv.goals.values())
    if colors_b != colors_g:
        return None
    normalize = not lv.arrows          # reachability is symmetric without arrows
    start_boxes = frozenset(lv.boxes.items())

    def key(player, boxes_fs, boxes_set):
        if normalize:
            return (min(_reach(lv, player, boxes_set)), boxes_fs)
        return (player, boxes_fs)

    sb = set(lv.boxes)
    start = key(lv.player, start_boxes, sb)
    parent = {start: None}
    q = deque([(start, lv.player)])
    explored = 0
    goal = None
    while q:
        state, real_player = q.popleft()
        explored += 1
        if explored > limit:
            if stats is not None:
                stats["explored"] = explored
            return None
        pos, bfs = state
        bdict = dict(bfs)
        if lv.is_solved(bdict):
            goal = state
            break
        bset = set(bdict)
        reach = _reach(lv, pos, bset)
        for b, c in bdict.items():
            for d, (dx, dy) in DIRS.items():
                stand = (b[0] - dx, b[1] - dy)
                if stand not in reach or not lv.can_enter(b, d):
                    continue
                others = bset - {b}
                f = lv.slide_target(others, b, d)
                if f is None or _corner_dead(lv, f, c):
                    continue
                nb = dict(bdict)
                del nb[b]
                nb[f] = c
                nfs = frozenset(nb.items())
                ns = key(b, nfs, set(nb))
                if ns not in parent:
                    parent[ns] = (state, b, d)
                    q.append((ns, b))
    if stats is not None:
        stats["explored"] = explored
    if goal is None:
        return None
    pushes = []
    s = goal
    while parent[s] is not None:
        prev, b, d = parent[s]
        pushes.append((prev, b, d))
        s = prev
    pushes.reverse()
    moves = []
    player = lv.player
    boxes = dict(lv.boxes)
    for prev, b, d in pushes:
        dx, dy = DIRS[d]
        stand = (b[0] - dx, b[1] - dy)
        walk = _path(lv, player, stand, set(boxes))
        if walk is None:
            return None
        moves.append(walk + d)
        c = boxes.pop(b)
        boxes[lv.slide_target(set(boxes), b, d)] = c
        player = b
    sol = "".join(moves)
    ok, _, _ = replay(lv, sol)
    return sol if ok else None


def score(par, pushes, states):
    return 1.5 * math.log10(max(states, 1)) + 0.12 * pushes + 0.01 * par


def rate(lv, limit=400_000):
    st = {}
    sol = solve(lv, limit, st)
    if sol is None:
        return None
    ok, pushes, slides = replay(lv, sol)
    return {"solution": sol, "par": len(sol), "pushes": pushes, "slides": slides,
            "states": st.get("explored", 0), "score": score(len(sol), pushes, st.get("explored", 0))}


# ======================================================================= generators
def _final_assignment(lv, solution):
    """Track box identities through the base solution: start cell -> final goal."""
    player = lv.player
    ident = {p: p for p in lv.boxes}          # current cell -> start cell
    for d in solution:
        dx, dy = DIRS[d]
        t = (player[0] + dx, player[1] + dy)
        if t in ident:
            ident[(t[0] + dx, t[1] + dy)] = ident.pop(t)
        player = t
    return {start: cur for cur, start in ident.items()}


def gen_color(base_rows, base_solution, base_rate, rng, limit=150_000):
    """Paint two boxes and two goals green. Pairings that differ from the natural
    one of the base solution force boxes to swap places, which is the fun part."""
    from itertools import combinations
    lv = Lv(base_rows)
    starts = sorted(lv.boxes)
    goals = sorted(lv.goals)
    combos = [(bi, gi) for bi in combinations(starts, 2) for gi in combinations(goals, 2)]
    rng.shuffle(combos)
    best = None
    for bi, gi in combos[:12]:
        cand = Lv(base_rows)
        for s_ in bi:
            cand.boxes[s_] = 1
        for g in gi:
            cand.goals[g] = 1
        cand.rules = ["color"]
        r = rate(cand, limit)
        if r and r["pushes"] > base_rate["pushes"] + 1 and (best is None or r["score"] > best[1]["score"]):
            best = (cand, r)
    return best


def _open_cells(lv):
    occupied = set(lv.boxes) | set(lv.goals) | {lv.player}
    return [p for p in lv.floor if p not in occupied]


def gen_ice(base_rows, base_solution, base_rate, rng, extra_rules=None, start=None):
    best = None
    for _ in range(14):
        cand = start() if start else Lv(base_rows)
        cells = _open_cells(cand)
        if len(cells) < 4:
            return None
        seed = rng.choice(cells)
        blob = {seed}
        frontier = [seed]
        size = rng.randint(3, 7)
        while frontier and len(blob) < size:
            c = frontier.pop(rng.randrange(len(frontier)))
            for dx, dy in DIRS.values():
                n = (c[0] + dx, c[1] + dy)
                if n in cells and n not in blob and len(blob) < size:
                    blob.add(n)
                    frontier.append(n)
        cand.ice = blob
        cand.rules = (extra_rules or []) + ["ice"]
        r = rate(cand)
        if r and r["slides"] > 0 and (best is None or r["score"] > best[1]["score"]):
            best = (cand, r)
    if best and best[1]["pushes"] != base_rate["pushes"] or (best and best[1]["slides"] >= 2):
        return best
    return None


def _corridor_cells(lv):
    out = []
    for p in _open_cells(lv):
        x, y = p
        h = (x - 1, y) in lv.floor and (x + 1, y) in lv.floor
        v = (x, y - 1) in lv.floor and (x, y + 1) in lv.floor
        hw = (x, y - 1) not in lv.floor and (x, y + 1) not in lv.floor
        vw = (x - 1, y) not in lv.floor and (x + 1, y) not in lv.floor
        if h and hw:
            out.append((p, "LR"))
        elif v and vw:
            out.append((p, "UD"))
    return out


def _walked(lv, solution):
    """cell -> set of directions the player entered it with in `solution`"""
    used = {}
    player = lv.player
    for d in solution:
        dx, dy = DIRS[d]
        player = (player[0] + dx, player[1] + dy)
        used.setdefault(player, set()).add(d)
    return used


OPPOSITE = {"U": "D", "D": "U", "L": "R", "R": "L"}


def gen_oneway(base_rows, base_solution, base_rate, rng, extra_rules=None, start=None):
    """Put 1-2 arrows on cells the base solution walks through, pointing against
    one of the directions it used, so the old route no longer works."""
    best = None
    probe = start() if start else Lv(base_rows)
    walked = _walked(probe, base_solution)
    occupied = set(probe.boxes) | set(probe.goals) | {probe.player}
    cells = [c for c in walked if c not in occupied]
    if not cells:
        return None
    for _ in range(14):
        cand = start() if start else Lv(base_rows)
        k = min(len(cells), rng.randint(1, 2))
        cand.arrows = {}
        for c in rng.sample(cells, k):
            cand.arrows[c] = OPPOSITE[rng.choice(sorted(walked[c]))]
        cand.rules = (extra_rules or []) + ["oneway"]
        ok, _, _ = replay(cand, base_solution)
        if ok:
            continue                              # arrows do not change anything
        r = rate(cand)
        if r and r["pushes"] >= base_rate["pushes"] and (best is None or r["score"] > best[1]["score"]):
            best = (cand, r)
    return best


def gen_mix(base_rows, base_solution, base_rate, rng):
    kind = rng.choice(["color+ice", "color+oneway", "ice+oneway"])
    if kind.startswith("color"):
        col = gen_color(base_rows, base_solution, base_rate, rng)
        if not col:
            return None
        colored = col[0]

        def start():
            c = Lv(base_rows)
            c.boxes = dict(colored.boxes)
            c.goals = dict(colored.goals)
            return c
        fn = gen_ice if kind.endswith("ice") else gen_oneway
        res = fn(base_rows, col[1]["solution"], col[1], rng, extra_rules=["color"], start=start)
    else:
        ice = gen_ice(base_rows, base_solution, base_rate, rng)
        if not ice:
            return None
        iced = ice[0]

        def start():
            c = Lv(base_rows)
            c.ice = set(iced.ice)
            return c
        res = gen_oneway(base_rows, ice[1]["solution"], ice[1], rng, extra_rules=["ice"], start=start)
    return res


# ======================================================================= intros
INTROS = {
    "color": [
        (["#########",
          "#   .   #",
          "# @$ $  #",
          "#   .   #",
          "#########"], [("boxcolor", "5,2,1"), ("goalcolor", "4,3,1")], "짝 맞추기", "Matching Pairs"),
    ],
    "ice": [
        (["##########",
          "#@ $    .#",
          "##########"], [("ice", "4,1;5,1;6,1")], "미끄러운 길", "Slippery Path"),
    ],
    "oneway": [
        (["#########",
          "#@ $  . #",
          "#########"], [("oneway", "4,1,R")], "한 방향 문", "One-Way Door"),
    ],
}


# ======================================================================= io
def block(lv, r, name="", name_en="", extra=None):
    meta = []
    if name:
        meta.append(("name", name))
    if name_en:
        meta.append(("name_en", name_en))
    meta += lv.meta_lines() + (extra or [])
    meta += [("par", str(r["par"])), ("solution", r["solution"])]
    return "\n".join(f"; {k}: {v}" for k, v in meta) + "\n" + "\n".join(lv.rows)


def _norm(rows):
    return "\n".join(x.rstrip() for x in rows)


def build():
    import build_tiers as bt
    rng = random.Random(20261006)
    rated = json.loads((ROOT / "levels/src/boxoban_rated.json").read_text(encoding="utf-8"))
    used = set()
    for t in ("easy", "normal", "hard", "expert"):
        for l in parse((ROOT / f"levels/{t}.txt").read_text(encoding="utf-8")):
            used.add(_norm(l["rows"]))
    pool = []
    seen = set()
    for r in rated:
        rows = bt.trim(list(r["rows"]))
        k = _norm(rows)
        if k in used or k in seen:
            continue
        seen.add(k)
        r = dict(r)
        r["rows"] = rows
        r["score"] = score(r["par"], r["pushes"], r["states"])
        pool.append(r)
    pool.sort(key=lambda r: r["score"])
    print(f"unused boxoban pool: {len(pool)}", flush=True)

    # Variant bases come from the easier 60% so the new rule, not raw size, is the challenge.
    n = len(pool)
    bases = pool[: int(n * 0.6)]
    rng.shuffle(bases)
    chapters = {"color": [], "ice": [], "oneway": [], "mix": []}
    taken = set()
    target = 30
    from multiprocessing import Pool
    cursor = 0
    with Pool(10) as workers:
        for ch in chapters:
            want = target - len(INTROS.get(ch, []))
            while len(chapters[ch]) < want and cursor < len(bases):
                batch = bases[cursor: cursor + 40]
                cursor += len(batch)
                jobs = [(ch, b["rows"], b["solution"], b["pushes"], 1000 + cursor + i) for i, b in enumerate(batch)]
                for b, res in zip(batch, workers.map(_gen_job, jobs)):
                    if res and len(chapters[ch]) < want:
                        chapters[ch].append(res)
                        taken.add(_norm(b["rows"]))
                print(f"  {ch}: {len(chapters[ch])}/{want} (bases tried {cursor})", flush=True)
    for ch, items in chapters.items():
        items.sort(key=lambda it: it[1]["score"])
        blocks = []
        for rows, meta, nm, nm_en in INTROS.get(ch, []):
            lv = Lv(rows, meta)
            lv.rules = [ch]
            r = rate(lv)
            assert r, ("intro unsolvable", ch, nm)
            blocks.append(block(lv, r, nm, nm_en))
        for lv, r in items:
            blocks.append(block(lv, r))
        (ROOT / f"levels/rule_{ch}.txt").write_text("\n\n".join(blocks) + "\n", encoding="utf-8")
        print(f"rule_{ch}.txt: {len(blocks)} levels")

    # Daily pool: everything left, split into 7 bands (Mon easiest .. Sun hardest)
    daily = [b for b in pool if _norm(b["rows"]) not in taken]
    bands = 7
    blocks = []
    for i, b in enumerate(daily):
        band = min(bands - 1, i * bands // len(daily))
        lv = Lv(b["rows"])
        r = {"par": b["par"], "solution": b["solution"]}
        blocks.append(block(lv, r, extra=[("band", str(band))]))
    (ROOT / "levels/daily.txt").write_text("\n\n".join(blocks) + "\n", encoding="utf-8")
    print(f"daily.txt: {len(blocks)} levels in {bands} bands")


GENS = {"color": gen_color, "ice": gen_ice, "oneway": gen_oneway, "mix": gen_mix}


def _gen_job(job):
    ch, rows, sol, pushes, seed = job
    try:
        return GENS[ch](rows, sol, {"pushes": pushes}, random.Random(seed))
    except Exception as e:  # a bad base must not kill the whole build
        print("generator error", ch, e, flush=True)
        return None


def check(path):
    bad = 0
    for i, l in enumerate(parse(Path(path).read_text(encoding="utf-8"))):
        lv = Lv(l["rows"], l["meta"])
        meta = dict(l["meta"])
        ok, _, _ = replay(lv, meta.get("solution", ""))
        if not ok:
            bad += 1
            print(f"[{i+1}] stored solution does not solve the level")
    print(f"{path}: {'OK' if bad == 0 else str(bad) + ' FAILED'}")
    return bad


if __name__ == "__main__":
    if sys.argv[1:2] == ["build"]:
        build()
    elif sys.argv[1:2] == ["check"]:
        sys.exit(1 if any(check(p) for p in sys.argv[2:]) else 0)
    else:
        print(__doc__)
