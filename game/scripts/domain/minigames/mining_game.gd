extends "res://scripts/domain/minigames/minigame.gd"
## Mining: a marker sweeps back and forth over a rock face; tap (press) when it is over the glowing vein.
## Five strikes; a centred hit scores 1, an edge hit 0.5. Difficulty 0..2 narrows the vein and speeds the marker.

const STRIKES := 5
const LIMIT := 24.0

var marker: float = 0.0
var dir: float = 1.0
var speed: float = 0.7
var vein: float = 0.5
var vein_w: float = 0.22
var strikes_left: int = STRIKES
var hits: Array = []              # per strike: 0, 0.5 or 1
var time_left: float = LIMIT
var holding: bool = false
var difficulty: int = 0
var _rng := RandomNumberGenerator.new()


func start(params: Dictionary, seed_value: int) -> void:
	super.start(params, seed_value)
	difficulty = clampi(int(params.get("difficulty", 0)), 0, 2)
	_rng.seed = seed_value
	marker = 0.0
	dir = 1.0
	speed = 0.7 + 0.25 * difficulty
	vein_w = 0.24 - 0.04 * difficulty
	vein = _rng.randf_range(0.2, 0.8)
	strikes_left = STRIKES
	hits = []
	time_left = LIMIT
	holding = false


func set_input(action: String, value: Variant) -> void:
	if action != "hold":
		return
	var down := bool(value)
	if down and not holding and not done:
		_strike()
	holding = down


func _strike() -> void:
	var d := absf(marker - vein)
	var h := 0.0
	if d <= vein_w * 0.25:
		h = 1.0
	elif d <= vein_w * 0.5:
		h = 0.5
	hits.append(h)
	strikes_left -= 1
	vein = _rng.randf_range(0.15, 0.85)
	if strikes_left <= 0:
		_finish()


func _finish() -> void:
	done = true
	var total := 0.0
	for h in hits:
		total += float(h)
	score = total / float(STRIKES)


func step(dt: float) -> void:
	if done:
		return
	time_left -= dt
	marker += dir * speed * dt
	if marker >= 1.0:
		marker = 1.0
		dir = -1.0
	elif marker <= 0.0:
		marker = 0.0
		dir = 1.0
	if time_left <= 0.0:
		time_left = 0.0
		_finish()


func snapshot() -> Dictionary:
	return {"kind": "mining", "marker": marker, "vein": vein, "vein_w": vein_w, "strikes_left": strikes_left, "hits": hits.duplicate(), "total": STRIKES,
			"time_left": time_left, "limit": LIMIT, "done": done, "caught": done and score >= 0.6, "escaped": done and score < 0.3}


func result() -> Dictionary:
	return {"score": clampf(score, 0.0, 1.0), "hits": hits.duplicate(), "time_left": time_left}
