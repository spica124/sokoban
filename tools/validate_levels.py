"""validate_levels.py - checks every level in a level file is solvable, computes
par (move count of the push-optimal solution) and a solution string, and
writes them back as "; par: N" / "; solution: URDL..." lines.

Usage:  python tools/validate_levels.py                 levels/levels.txt, write par
        python tools/validate_levels.py FILE            another file, write par
        python tools/validate_levels.py FILE --check    validate only, no write

Solver: BFS over push states (normalised player position + box set),
so it scales to 6-8 boxes. Pruning: dead squares (reverse-pull analysis)
and freeze deadlocks. The solution is push-optimal; its move count is used
as par (a fair target, possibly a few moves above the true move optimum).
"""
import sys
from collections import deque
from pathlib import Path

DEFAULT_FILE = Path(__file__).resolve().parent.parent / "levels" / "levels.txt"
DIRS = {"U": (0, -1), "D": (0, 1), "L": (-1, 0), "R": (1, 0)}
STATE_LIMIT = 6_000_000


# ---------------------------------------------------------------- parsing
def parse(text):
    """Split a level file into dicts: {"meta": [(k, v)...], "rows": [...]}"""
    levels, meta, rows = [], [], []
    for raw in text.splitlines():
        line = raw.rstrip("\r")
        if line.strip() == "":
            if rows:
                levels.append({"meta": meta, "rows": rows})
            meta, rows = [], []
        elif line.startswith(";"):
            k, _, v = line[1:].partition(":")
            meta.append((k.strip(), v.strip()))
        else:
            rows.append(line)
    if rows:
        levels.append({"meta": meta, "rows": rows})
    return levels


def build(rows):
    walls, goals, boxes, player = set(), set(), set(), None
    for y, row in enumerate(rows):
        for x, c in enumerate(row):
            p = (x, y)
            if c == "#":
                walls.add(p)
            elif c == "@":
                player = p
            elif c == "+":
                player = p; goals.add(p)
            elif c == "$":
                boxes.add(p)
            elif c == "*":
                boxes.add(p); goals.add(p)
            elif c == ".":
                goals.add(p)
    return walls, goals, frozenset(boxes), player


# ---------------------------------------------------------------- analysis
def interior(walls, player, w, h):
    """Floor cells reachable from the player ignoring boxes."""
    seen = {player}
    stack = [player]
    while stack:
        x, y = stack.pop()
        for dx, dy in DIRS.values():
            n = (x + dx, y + dy)
            if 0 <= n[0] < w and 0 <= n[1] < h and n not in walls and n not in seen:
                seen.add(n)
                stack.append(n)
    return seen


def live_squares(walls, goals, floor):
    """Squares from which a box can still reach some goal (reverse pulls,
    ignoring other boxes). Pushing a box onto a non-live square is a deadlock."""
    live = set(g for g in goals if g in floor)
    stack = list(live)
    while stack:
        bx, by = stack.pop()
        for dx, dy in DIRS.values():
            prev = (bx - dx, by - dy)          # where the box was before a push in (dx,dy)
            standing = (bx - 2 * dx, by - 2 * dy)  # where the player stood
            if prev in floor and standing in floor and prev not in live:
                live.add(prev)
                stack.append(prev)
    return live


def is_frozen(box, boxes, walls, goals, visiting=None):
    """Freeze deadlock: box cannot move on either axis and is not on a goal
    (boxes blocking each other are treated recursively)."""
    if visiting is None:
        visiting = set()
    visiting.add(box)
    x, y = box

    def blocked_axis(d1, d2):
        a = (x + d1[0], y + d1[1])
        b = (x + d2[0], y + d2[1])
        if a in walls or b in walls:
            return True
        for n in (a, b):
            if n in boxes and (n in visiting or is_frozen(n, boxes, walls, goals, visiting)):
                return True
        return False

    frozen = blocked_axis((0, -1), (0, 1)) and blocked_axis((-1, 0), (1, 0))
    return frozen


def any_frozen_off_goal(boxes, walls, goals, changed):
    """After a push only the moved box (and its neighbours) can newly freeze."""
    if changed in goals:
        # still check: a box on a goal may freeze a neighbour off-goal
        pass
    cx, cy = changed
    for b in [changed] + [(cx + dx, cy + dy) for dx, dy in DIRS.values()]:
        if b in boxes and b not in goals and is_frozen(b, boxes, walls, goals):
            return True
    return False


# ---------------------------------------------------------------- solver
def reachable(player, boxes, floor):
    seen = {player}
    stack = [player]
    while stack:
        x, y = stack.pop()
        for dx, dy in DIRS.values():
            n = (x + dx, y + dy)
            if n in floor and n not in boxes and n not in seen:
                seen.add(n)
                stack.append(n)
    return seen


def path(start, goal, boxes, floor):
    """Shortest move string from start to goal avoiding boxes."""
    if start == goal:
        return ""
    prev = {start: None}
    q = deque([start])
    while q:
        cur = q.popleft()
        for d, (dx, dy) in DIRS.items():
            n = (cur[0] + dx, cur[1] + dy)
            if n in floor and n not in boxes and n not in prev:
                prev[n] = (cur, d)
                if n == goal:
                    out = []
                    while prev[n] is not None:
                        n, d = prev[n]
                        out.append(d)
                    return "".join(reversed(out))
                q.append(n)
    return None


def solve(rows, limit=STATE_LIMIT, stats=None):
    """Returns (solution_string, error). solution is None on failure.
    If stats is a dict, stats["explored"] receives the number of states expanded."""
    walls, goals, boxes, player = build(rows)
    if player is None:
        return None, "no player"
    if len(boxes) != len(goals):
        return None, f"{len(boxes)} boxes vs {len(goals)} goals"
    h = len(rows)
    w = max(len(r) for r in rows)
    floor = interior(walls, player, w, h)
    if not goals <= floor:
        return None, "goal outside reachable area"
    if not boxes <= floor:
        return None, "box outside reachable area"
    live = live_squares(walls, goals, floor)
    for b in boxes:
        if b not in live:
            return None, f"box at {b} can never reach a goal"

    start_reach = reachable(player, boxes, floor)
    start = (min(start_reach), boxes)
    parent = {start: None}   # state -> (prev_state, box, dir)
    q = deque([start])
    explored = 0
    goal_state = None
    while q:
        state = q.popleft()
        explored += 1
        if explored > limit:
            if stats is not None:
                stats["explored"] = explored
            return None, f"search limit reached ({limit} states)"
        norm, bx = state
        if bx <= goals:
            goal_state = state
            break
        reach = reachable(norm, bx, floor)
        for b in bx:
            for d, (dx, dy) in DIRS.items():
                stand = (b[0] - dx, b[1] - dy)
                target = (b[0] + dx, b[1] + dy)
                if stand not in reach or target in bx or target not in live:
                    continue
                nb = (bx - {b}) | {target}
                if any_frozen_off_goal(nb, walls, goals, target):
                    continue
                nreach = reachable(b, nb, floor)
                ns = (min(nreach), nb)
                if ns not in parent:
                    parent[ns] = (state, b, d)
                    q.append(ns)
    if stats is not None:
        stats["explored"] = explored
    if goal_state is None:
        return None, "unsolvable"

    # reconstruct pushes, then expand into moves with real player positions
    pushes = []
    s = goal_state
    while parent[s] is not None:
        prev_state, b, d = parent[s]
        pushes.append((prev_state[1], b, d))
        s = prev_state
    pushes.reverse()
    moves = []
    pos = player
    for bx, b, d in pushes:
        dx, dy = DIRS[d]
        stand = (b[0] - dx, b[1] - dy)
        walk = path(pos, stand, bx, floor)
        if walk is None:
            return None, "internal error: path reconstruction failed"
        moves.append(walk)
        moves.append(d)
        pos = b
    return "".join(moves), None


def count_pushes(rows, sol):
    walls, goals, boxes, player = build(rows)
    boxes = set(boxes)
    n = 0
    for d in sol:
        dx, dy = DIRS[d]
        nxt = (player[0] + dx, player[1] + dy)
        if nxt in boxes:
            boxes.remove(nxt)
            boxes.add((nxt[0] + dx, nxt[1] + dy))
            n += 1
        player = nxt
    return n


# ---------------------------------------------------------------- main
def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    check_only = "--check" in sys.argv
    file = Path(args[0]) if args else DEFAULT_FILE
    levels = parse(file.read_text(encoding="utf-8"))
    ok = True
    out = []
    for i, lv in enumerate(levels):
        meta = dict(lv["meta"])
        name = meta.get("name_en") or meta.get("name", f"#{i+1}")
        boxes = sum(r.count("$") + r.count("*") for r in lv["rows"])
        sol, err = solve(lv["rows"])
        if sol is None:
            ok = False
            print(f"[{i+1:2d}] {name}: FAIL - {err}", flush=True)
        else:
            print(f"[{i+1:2d}] {name}: ok  boxes={boxes}  par={len(sol)}  pushes={count_pushes(lv['rows'], sol)}", flush=True)
        if sol is not None:
            kept = [(k, v) for k, v in lv["meta"] if k not in ("par", "solution")]
            kept += [("par", str(len(sol))), ("solution", sol)]
        else:
            kept = list(lv["meta"])   # keep the previous par/solution on failure
        out.append("\n".join(f"; {k}: {v}" for k, v in kept) + "\n" + "\n".join(lv["rows"]))
    if not check_only and ok:
        file.write_text("\n\n".join(out) + "\n", encoding="utf-8")
        print(f"{file.name} updated with par/solution")
    elif not check_only:
        print("file NOT written: some levels failed")
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
