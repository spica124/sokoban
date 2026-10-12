## Board.gd — pure sokoban rules, no rendering.
##
## Level text format (standard):
##   #  wall      @  player      +  player on goal
##   $  box       *  box on goal .  goal        space = floor
##
## Rule variants come from level metadata (see tools/variants.py, which is the
## reference implementation; both must behave identically):
##   color  : boxes / goals carry a color (0 default, 1 = green). A box only
##            counts when it sits on a goal of its own color.
##   ice    : a pushed box that lands on ice keeps sliding while the next cell is
##            enterable floor without a box. Players never slide.
##   oneway : an arrow cell can only be entered moving in the arrow direction
##            (player and boxes alike).
##
## Coordinates are Vector2i(x, y). The level is padded by one wall ring, so
## metadata coordinates (given in the level's own rows) are shifted by (1, 1).
class_name Board
extends RefCounted

const LETTER := {"U": Vector2i.UP, "D": Vector2i.DOWN, "L": Vector2i.LEFT, "R": Vector2i.RIGHT}
const PAD := Vector2i(1, 1)

var width := 0
var height := 0
var walls := {}     # Vector2i -> true
var floors := {}    # interior floor cells (reachable area), used for drawing
var goals := {}     # Vector2i -> color (int)
var boxes := {}     # Vector2i -> color (int)
var ice := {}       # Vector2i -> true
var arrows := {}    # Vector2i -> Vector2i direction
var rules: Array = []
var player := Vector2i.ZERO

var moves := 0
var pushes := 0

## Undo stack. Each entry: {player, box_from, box_to} (box_* are null when no push)
var history: Array = []


## ---------- construction ----------
## `meta` is the level dictionary from Levels.gd (or any dict with the optional
## keys rules / boxcolor / goalcolor / ice / oneway).
static func from_rows(raw_rows: Array, meta := {}) -> Board:
	var b := Board.new()
	# Pad one wall layer around the level so edge floors (as in the
	# StarCraft maps, which have no border row) are always closed off.
	var inner_w := 0
	for row in raw_rows:
		inner_w = max(inner_w, row.length())
	var rows: Array = ["#".repeat(inner_w + 2)]
	for row in raw_rows:
		rows.append("#" + row.rpad(inner_w, "#") + "#")
	rows.append("#".repeat(inner_w + 2))
	b.height = rows.size()
	b.width = inner_w + 2
	for y in b.height:
		var row: String = rows[y]
		for x in row.length():
			var c := row[x]
			var p := Vector2i(x, y)
			match c:
				"#": b.walls[p] = true
				"@": b.player = p
				"+": b.player = p; b.goals[p] = 0
				"$": b.boxes[p] = 0
				"*": b.boxes[p] = 0; b.goals[p] = 0
				".": b.goals[p] = 0
	b._compute_floors()
	b._apply_meta(meta)
	return b


func _apply_meta(meta: Dictionary) -> void:
	for part in str(meta.get("rules", "")).split(",", false):
		rules.append(part.strip_edges())
	for item in _cells(str(meta.get("boxcolor", ""))):
		if boxes.has(item[0]):
			boxes[item[0]] = int(item[1])
	for item in _cells(str(meta.get("goalcolor", ""))):
		if goals.has(item[0]):
			goals[item[0]] = int(item[1])
	for item in _cells(str(meta.get("ice", ""))):
		ice[item[0]] = true
	for item in _cells(str(meta.get("oneway", ""))):
		if LETTER.has(item[1]):
			arrows[item[0]] = LETTER[item[1]]


## "x,y,v;x,y,v" -> [[Vector2i(x+1, y+1), "v"], ...]
static func _cells(text: String) -> Array:
	var out: Array = []
	for part in text.split(";", false):
		var bits := part.strip_edges().split(",")
		if bits.size() < 2:
			continue
		var value := bits[2] if bits.size() > 2 else "1"
		out.append([Vector2i(int(bits[0]), int(bits[1])) + PAD, value])
	return out


## Flood fill from the player through non-wall cells. Cells outside the walls
## are not floor and are not drawn.
func _compute_floors() -> void:
	floors.clear()
	var stack := [player]
	floors[player] = true
	while not stack.is_empty():
		var p: Vector2i = stack.pop_back()
		for d in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var n: Vector2i = p + d
			if n.x < 0 or n.y < 0 or n.x >= width or n.y >= height:
				continue
			if walls.has(n) or floors.has(n):
				continue
			floors[n] = true
			stack.push_back(n)


## ---------- queries ----------
func is_wall(p: Vector2i) -> bool:
	return walls.has(p)


func has_rule(rule: String) -> bool:
	return rule in rules


## A cell can be entered only if it is real floor (inside the level) and empty
func is_free(p: Vector2i) -> bool:
	return floors.has(p) and not boxes.has(p)


## One-way arrows: a cell with an arrow accepts entry only along the arrow
func can_enter(cell: Vector2i, dir: Vector2i) -> bool:
	return not arrows.has(cell) or arrows[cell] == dir


## True when the box at `cell` sits on a goal of its own color
func box_home(cell: Vector2i) -> bool:
	return boxes.has(cell) and int(goals.get(cell, -1)) == int(boxes[cell])


func is_solved() -> bool:
	for b in boxes.keys():
		if not box_home(b):
			return false
	return true


func boxes_on_goals() -> int:
	var n := 0
	for b in boxes.keys():
		if box_home(b):
			n += 1
	return n


## Where a box at `from` ends up when pushed in `dir` (the box must already be
## removed from `boxes`). Returns null when the push is blocked.
func _slide_target(from: Vector2i, dir: Vector2i):
	var t := from + dir
	if not floors.has(t) or boxes.has(t) or not can_enter(t, dir):
		return null
	var cur := t
	while ice.has(cur):
		var n := cur + dir
		if floors.has(n) and not boxes.has(n) and can_enter(n, dir):
			cur = n
		else:
			break
	return cur


## ---------- actions ----------
## Try to move the player one cell. Returns a result dictionary:
##   moved: bool, pushed: bool, from: Vector2i, to: Vector2i,
##   box_from / box_to: Vector2i (only when pushed), slid: int (extra cells on ice)
func try_move(dir: Vector2i) -> Dictionary:
	var target := player + dir
	var result := {"moved": false, "pushed": false, "from": player, "to": target, "slid": 0}
	if not floors.has(target) or not can_enter(target, dir):
		return result
	if boxes.has(target):
		var color: int = boxes[target]
		boxes.erase(target)
		var final = _slide_target(target, dir)
		if final == null:
			boxes[target] = color
			return result
		boxes[final] = color
		result["pushed"] = true
		result["box_from"] = target
		result["box_to"] = final
		result["slid"] = (final - target).length() as int - 1
		pushes += 1
		history.push_back({"player": player, "box_from": target, "box_to": final})
	else:
		history.push_back({"player": player, "box_from": null, "box_to": null})
	player = target
	moves += 1
	result["moved"] = true
	return result


## Undo the last move. Returns the undone entry (or empty dict if nothing to undo).
func undo() -> Dictionary:
	if history.is_empty():
		return {}
	var entry: Dictionary = history.pop_back()
	var prev_player: Vector2i = player
	player = entry["player"]
	moves = max(moves - 1, 0)
	if entry["box_from"] != null:
		var color: int = boxes[entry["box_to"]]
		boxes.erase(entry["box_to"])
		boxes[entry["box_from"]] = color
		pushes = max(pushes - 1, 0)
	return {"player_from": prev_player, "player_to": player,
			"box_from": entry["box_to"], "box_to": entry["box_from"]}


## ---------- helpers for hints ----------
## Cells the player can walk to right now (respects boxes and arrows)
func reachable(from := Vector2i(-1, -1)) -> Dictionary:
	var start := player if from == Vector2i(-1, -1) else from
	var seen := {start: true}
	var stack := [start]
	while not stack.is_empty():
		var cur: Vector2i = stack.pop_back()
		for d in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var n: Vector2i = cur + d
			if floors.has(n) and not boxes.has(n) and not seen.has(n) and can_enter(n, d):
				seen[n] = true
				stack.push_back(n)
	return seen


## Shortest walk (list of cells, excluding the start) from the player to `goal`
func walk_path(goal: Vector2i) -> Array:
	if goal == player:
		return []
	var prev := {player: player}
	var queue: Array = [player]
	while not queue.is_empty():
		var cur: Vector2i = queue.pop_front()
		for d in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var n: Vector2i = cur + d
			if prev.has(n) or not floors.has(n) or boxes.has(n) or not can_enter(n, d):
				continue
			prev[n] = cur
			if n == goal:
				var path: Array = []
				var c := n
				while c != player:
					path.push_front(c)
					c = prev[c]
				return path
			queue.push_back(n)
	return []


## Identity of the current position for hint lookups. Without arrows every
## cell the player can reach is equivalent, so the smallest one stands in.
func state_key() -> String:
	var colored: Array = []
	for b in boxes.keys():
		colored.append("%d:%d:%d" % [b.x, b.y, int(boxes[b])])
	colored.sort()
	var who := player
	if arrows.is_empty():
		var best := player
		for c in reachable().keys():
			if c.y < best.y or (c.y == best.y and c.x < best.x):
				best = c
		who = best
	return "%d,%d|%s" % [who.x, who.y, ",".join(colored)]


## Plain data copy for the hint solver thread
func snapshot() -> Dictionary:
	return {
		"width": width, "height": height,
		"floors": floors.duplicate(), "goals": goals.duplicate(), "boxes": boxes.duplicate(),
		"ice": ice.duplicate(), "arrows": arrows.duplicate(), "player": player,
	}
