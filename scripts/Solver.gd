## Solver.gd — push-optimal search used by the hint button.
##
## Mirrors tools/variants.py (same rules: colors, ice sliding, one-way arrows).
## Works on plain packed arrays so it can run on a worker thread.
##
##   var r := Solver.first_push(board.snapshot())
##   r = {"status": "ok"|"dead"|"limit"|"solved", "box": Vector2i, "dir": Vector2i, "pushes": int}
##
## "ok"    : `box` pushed in `dir` is the first push of a shortest solution
## "dead"  : no solution exists from this position (the player must undo)
## "limit" : search budget ran out before an answer was found
##
## Search: A* over push states. The estimate is, per box, the fewest pushes that
## could bring it to any goal of its color in a relaxed world: no other boxes,
## the player can stand anywhere, and a push onto ice may stop at any cell of the
## slide (another box could cut it short). Every real push is one of those
## relaxed pushes, so the estimate never overestimates and changes by at most one
## per push: the first solution found is optimal.
## Player position: every cell the player can walk to and back from is the same
## state, so it is stored as the smallest such cell (without arrows that is just
## the whole reachable area).
class_name Solver
extends RefCounted

const DIRV := [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
const FAR := 1 << 20


static func first_push(snap: Dictionary, max_states := 400000, max_ms := 12000) -> Dictionary:
	var w: int = snap["width"]
	var h: int = snap["height"]
	var n := w * h
	var off := [-w, w, -1, 1]
	var floor_ := PackedByteArray()
	floor_.resize(n)
	var goalc := PackedInt32Array()
	goalc.resize(n)
	goalc.fill(-1)
	var icec := PackedByteArray()
	icec.resize(n)
	var arrow := PackedInt32Array()
	arrow.resize(n)              # 0 = none, else direction index + 1
	for c in snap["floors"]:
		floor_[c.y * w + c.x] = 1
	for c in snap["goals"]:
		goalc[c.y * w + c.x] = int(snap["goals"][c])
	for c in snap["ice"]:
		icec[c.y * w + c.x] = 1
	for c in snap["arrows"]:
		arrow[c.y * w + c.x] = DIRV.find(snap["arrows"][c]) + 1
	var has_arrows: bool = not snap["arrows"].is_empty()

	# corner cells: a box parked there can never move again
	var corner := PackedByteArray()
	corner.resize(n)
	for i in n:
		if floor_[i] == 0:
			continue
		var up := floor_[i - w] == 0
		var down := floor_[i + w] == 0
		var left := floor_[i - 1] == 0
		var right := floor_[i + 1] == 0
		corner[i] = 1 if (up or down) and (left or right) else 0

	# per-color lower bound on pushes from each cell to a goal of that color
	var edges := _relaxed_pushes(floor_, icec, arrow, off, n)
	var dist: Array = [_push_distance(0, goalc, edges, n), _push_distance(1, goalc, edges, n)]

	var start_codes := PackedInt32Array()
	for c in snap["boxes"]:
		var i: int = c.y * w + c.x
		var col: int = int(snap["boxes"][c])
		if corner[i] == 1 and goalc[i] != col:
			return {"status": "dead"}
		if dist[col][i] >= FAR:
			return {"status": "dead"}
		start_codes.append(i * 2 + col)
	start_codes.sort()
	var p0: Vector2i = snap["player"]

	var occ := PackedByteArray()
	occ.resize(n)
	var seen := PackedByteArray()
	seen.resize(n)
	var seen2 := PackedByteArray()      # scratch for the children's canonical cell
	seen2.resize(n)
	var back := PackedByteArray()       # scratch for the backward flood (arrows only)
	back.resize(n)

	var started := Time.get_ticks_msec()
	var root_player := _canonical(p0.y * w + p0.x, start_codes, floor_, arrow, off, occ, seen, back, has_arrows)
	var root_key := _key(root_player, start_codes)
	# node storage: parallel arrays indexed by node id
	var n_player := PackedInt32Array([root_player])
	var n_codes: Array = [start_codes]
	var n_g := PackedInt32Array([0])
	var n_parent := PackedInt32Array([-1])
	var n_box := PackedInt32Array([-1])
	var n_dir := PackedInt32Array([-1])
	var best := {root_key: 0}            # key -> best g found
	var heap := PackedInt64Array()
	_push(heap, _h(start_codes, dist), 0, 0)
	var expanded := 0
	while not heap.is_empty():
		var top := _pop(heap)
		var id := top & 0xFFFFFF
		var g: int = n_g[id]
		var codes: PackedInt32Array = n_codes[id]
		var pl: int = n_player[id]
		if int(best.get(_key(pl, codes), FAR)) < g:
			continue                     # a cheaper route to this state was found later
		expanded += 1
		if expanded > max_states or (expanded % 256 == 0 and Time.get_ticks_msec() - started > max_ms):
			return {"status": "limit"}
		if _solved(codes, goalc):
			return _unwind(id, n_parent, n_box, n_dir, w, g)
		occ.fill(0)
		for code in codes:
			occ[code >> 1] = 1
		_reach(pl, floor_, arrow, off, occ, seen)
		for bi in codes.size():
			var code: int = codes[bi]
			var b := code >> 1
			var col := code & 1
			for d in 4:
				var stand: int = b - off[d]
				if seen[stand] == 0:
					continue
				if arrow[b] != 0 and arrow[b] != d + 1:
					continue
				occ[b] = 0
				var dest := _slide(b, d, floor_, icec, arrow, off, occ)
				occ[b] = 1
				if dest < 0 or (corner[dest] == 1 and goalc[dest] != col):
					continue
				if dist[col][dest] >= FAR:
					continue                 # that box could never reach a goal again
				var nc := codes.duplicate()
				nc[bi] = dest * 2 + col
				nc.sort()
				occ[b] = 0
				occ[dest] = 1
				var np := _reach(b, floor_, arrow, off, occ, seen2)
				if has_arrows:
					np = _scc_low(b, arrow, off, occ, seen2, back)
				occ[dest] = 0
				occ[b] = 1
				var nk := _key(np, nc)
				if int(best.get(nk, FAR)) <= g + 1:
					continue
				best[nk] = g + 1
				var nid := n_g.size()
				n_player.append(np)
				n_codes.append(nc)
				n_g.append(g + 1)
				n_parent.append(id)
				n_box.append(b)
				n_dir.append(d)
				_push(heap, g + 1 + _h(nc, dist), g + 1, nid)
	return {"status": "dead"}


static func _key(player: int, codes: PackedInt32Array) -> PackedInt32Array:
	var k := codes.duplicate()
	k.append(player)
	return k


static func _h(codes: PackedInt32Array, dist: Array) -> int:
	var s := 0
	for code in codes:
		s += dist[code & 1][code >> 1]
	return s


## Every relaxed push as a flat edge list [from0, to0, from1, to1, ...]:
## the box at `from` is pushed one way and may stop on any cell of its slide.
## Arrows still limit which cells a box may enter.
static func _relaxed_pushes(floor_: PackedByteArray, icec: PackedByteArray, arrow: PackedInt32Array,
		off: Array, n: int) -> PackedInt32Array:
	var edges := PackedInt32Array()
	for c in n:
		if floor_[c] == 0:
			continue
		for d in 4:
			if floor_[c - off[d]] == 0:
				continue                     # no room for the player behind the box
			var t: int = c + off[d]
			while floor_[t] == 1 and (arrow[t] == 0 or arrow[t] == d + 1):
				edges.append(c)
				edges.append(t)
				if icec[t] == 0:
					break
				t += off[d]
	return edges


## Fewest relaxed pushes from each cell to a goal of `color` (FAR = never).
## Unit-weight relaxation over the edge list; the boards are small.
static func _push_distance(color: int, goalc: PackedInt32Array, edges: PackedInt32Array, n: int) -> PackedInt32Array:
	var dist := PackedInt32Array()
	dist.resize(n)
	dist.fill(FAR)
	for i in n:
		if goalc[i] == color:
			dist[i] = 0
	var changed := true
	while changed:
		changed = false
		for k in range(0, edges.size(), 2):
			var v: int = dist[edges[k + 1]] + 1
			if v < dist[edges[k]]:
				dist[edges[k]] = v
				changed = true
	return dist


## ---------- binary heap of (priority, tie-break, id) packed into one int ----------
## Lower f first; on ties prefer the deeper node (larger g) to reach goals sooner.
static func _push(heap: PackedInt64Array, f: int, g: int, id: int) -> void:
	var v: int = (f << 44) | ((4095 - min(g, 4095)) << 24) | id
	heap.append(v)
	var i := heap.size() - 1
	while i > 0:
		var parent := (i - 1) >> 1
		if heap[parent] <= heap[i]:
			break
		var tmp := heap[parent]
		heap[parent] = heap[i]
		heap[i] = tmp
		i = parent


static func _pop(heap: PackedInt64Array) -> int:
	var top := heap[0]
	var last := heap[heap.size() - 1]
	heap.resize(heap.size() - 1)
	if heap.is_empty():
		return top
	heap[0] = last
	var i := 0
	var size := heap.size()
	while true:
		var l := i * 2 + 1
		var r := l + 1
		var m := i
		if l < size and heap[l] < heap[m]:
			m = l
		if r < size and heap[r] < heap[m]:
			m = r
		if m == i:
			break
		var tmp := heap[m]
		heap[m] = heap[i]
		heap[i] = tmp
		i = m
	return top


static func _solved(codes: PackedInt32Array, goalc: PackedInt32Array) -> bool:
	for code in codes:
		if goalc[code >> 1] != (code & 1):
			return false
	return true


## Flood fill of walkable cells into `seen` (1 = reachable).
## Returns the smallest reached index (the canonical player cell).
static func _reach(start: int, floor_: PackedByteArray, arrow: PackedInt32Array, off: Array,
		occ: PackedByteArray, seen: PackedByteArray) -> int:
	seen.fill(0)
	seen[start] = 1
	var low := start
	var stack := PackedInt32Array()
	stack.resize(256)
	stack[0] = start
	var top := 1
	while top > 0:
		top -= 1
		var cur: int = stack[top]
		for d in 4:
			var nx: int = cur + off[d]
			if seen[nx] == 1 or floor_[nx] == 0 or occ[nx] == 1:
				continue
			if arrow[nx] != 0 and arrow[nx] != d + 1:
				continue
			seen[nx] = 1
			if nx < low:
				low = nx
			if top >= stack.size():
				stack.resize(stack.size() * 2)
			stack[top] = nx
			top += 1
	return low


## Canonical player cell for the start position (see _scc_low for arrows)
static func _canonical(start: int, codes: PackedInt32Array, floor_: PackedByteArray, arrow: PackedInt32Array,
		off: Array, occ: PackedByteArray, seen: PackedByteArray, back: PackedByteArray, has_arrows: bool) -> int:
	occ.fill(0)
	for code in codes:
		occ[code >> 1] = 1
	var low := _reach(start, floor_, arrow, off, occ, seen)
	return _scc_low(start, arrow, off, occ, seen, back) if has_arrows else low


## With arrows the player may get somewhere without a way back, so only cells
## that can also walk back to `start` count as the same position. `fwd` holds the
## forward flood from `start`; this walks backwards inside it and returns the
## smallest cell found (the representative of that strongly connected group).
static func _scc_low(start: int, arrow: PackedInt32Array, off: Array, occ: PackedByteArray,
		fwd: PackedByteArray, back: PackedByteArray) -> int:
	back.fill(0)
	back[start] = 1
	var low := start
	var stack := PackedInt32Array([start])
	while not stack.is_empty():
		var cur: int = stack[stack.size() - 1]
		stack.resize(stack.size() - 1)
		for d in 4:
			var x: int = cur - off[d]        # x steps in direction d onto cur
			if back[x] == 1 or fwd[x] == 0 or occ[x] == 1:
				continue
			if arrow[cur] != 0 and arrow[cur] != d + 1:
				continue
			back[x] = 1
			if x < low:
				low = x
			stack.append(x)
	return low


static func _slide(from: int, d: int, floor_: PackedByteArray, icec: PackedByteArray,
		arrow: PackedInt32Array, off: Array, occ: PackedByteArray) -> int:
	var t: int = from + off[d]
	if floor_[t] == 0 or occ[t] == 1 or (arrow[t] != 0 and arrow[t] != d + 1):
		return -1
	var cur := t
	while icec[cur] == 1:
		var nx: int = cur + off[d]
		if floor_[nx] == 1 and occ[nx] == 0 and (arrow[nx] == 0 or arrow[nx] == d + 1):
			cur = nx
		else:
			break
	return cur


## Walk back from the solved node to the first push after the root
static func _unwind(id: int, parent: PackedInt32Array, box: PackedInt32Array, dir: PackedInt32Array, w: int, pushes: int) -> Dictionary:
	if parent[id] < 0:
		return {"status": "solved"}
	var cur := id
	while parent[parent[cur]] >= 0:
		cur = parent[cur]
	var b: int = box[cur]
	return {"status": "ok", "box": Vector2i(b % w, floori(float(b) / w)), "dir": DIRV[dir[cur]], "pushes": pushes}
