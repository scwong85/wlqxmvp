extends "res://scripts/domain/minigames/minigame.gd"
## Fishing: hold to lift the hook bar, release to let it sink; keep the fish inside the bar to fill the catch meter.
## Difficulty 0..2 makes the fish faster and the bar shorter.

const LIMIT := 20.0
const GRAVITY := 1.1
const LIFT := 2.6

var hook: float = 0.2         # bottom of the bar, 0..1 (0 = bottom of the track)
var hook_v: float = 0.0
var bar: float = 0.26         # bar height
var fish: float = 0.5
var fish_target: float = 0.5
var fish_speed: float = 0.5
var retarget: float = 1.0
var progress: float = 0.3
var time_left: float = LIMIT
var holding: bool = false
var caught: bool = false
var escaped: bool = false
var difficulty: int = 0
var _rng := RandomNumberGenerator.new()


func start(params: Dictionary, seed_value: int) -> void:
	super.start(params, seed_value)
	difficulty = clampi(int(params.get("difficulty", 0)), 0, 2)
	_rng.seed = seed_value
	hook = 0.2
	hook_v = 0.0
	bar = 0.28 - 0.04 * difficulty
	fish = _rng.randf_range(0.3, 0.7)
	fish_target = fish
	fish_speed = 0.35 + 0.18 * difficulty
	retarget = 0.0
	progress = 0.3
	time_left = LIMIT
	holding = false
	caught = false
	escaped = false


func set_input(action: String, value: Variant) -> void:
	if action == "hold":
		holding = bool(value)


func step(dt: float) -> void:
	if done:
		return
	time_left -= dt
	retarget -= dt
	if retarget <= 0.0:
		fish_target = _rng.randf_range(0.05, 0.95)
		retarget = _rng.randf_range(0.7, 1.7) - 0.15 * difficulty
	fish = move_toward(fish, fish_target, fish_speed * dt)
	hook_v += (LIFT if holding else -GRAVITY) * dt
	hook_v = clampf(hook_v, -1.2, 1.2)
	hook += hook_v * dt
	if hook < 0.0:
		hook = 0.0
		hook_v = 0.0
	if hook > 1.0 - bar:
		hook = 1.0 - bar
		hook_v = 0.0
	var inside := fish >= hook and fish <= hook + bar
	progress += (0.24 if inside else -0.13) * dt
	progress = clampf(progress, 0.0, 1.0)
	if progress >= 1.0:
		caught = true
		done = true
		score = 0.8 + 0.2 * clampf(time_left / LIMIT, 0.0, 1.0)
	elif progress <= 0.0:
		escaped = true
		done = true
		score = 0.0
	elif time_left <= 0.0:
		done = true
		time_left = 0.0
		score = progress * 0.8


func snapshot() -> Dictionary:
	return {"hook": hook, "bar": bar, "fish": fish, "progress": progress, "time_left": time_left, "limit": LIMIT,
			"caught": caught, "escaped": escaped, "done": done, "holding": holding}


func result() -> Dictionary:
	return {"score": clampf(score, 0.0, 1.0), "caught": caught, "escaped": escaped, "time_left": time_left}
