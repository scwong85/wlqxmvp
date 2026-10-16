extends "res://scripts/domain/minigames/minigame.gd"
## Music: notes drift toward a line; tap (press) as a note reaches it. 12 notes; a tap within the window scores 1, within
## twice the window 0.5. Difficulty 0..2 tightens the window and speeds the tempo.

const NOTES := 12

var t: float = 0.0
var times: Array = []             # note arrival times
var state: Array = []             # per note: -1 pending, else the score earned
var window: float = 0.22
var lead_time: float = 1.6        # how long a note is visible before it arrives
var holding: bool = false
var difficulty: int = 0
var _rng := RandomNumberGenerator.new()


func start(params: Dictionary, seed_value: int) -> void:
	super.start(params, seed_value)
	difficulty = clampi(int(params.get("difficulty", 0)), 0, 2)
	_rng.seed = seed_value
	t = 0.0
	window = 0.24 - 0.04 * difficulty
	lead_time = 1.6 - 0.2 * difficulty
	times = []
	state = []
	var at := 1.6
	for i in NOTES:
		times.append(at)
		state.append(-1.0)
		at += _rng.randf_range(0.7, 1.1) - 0.1 * difficulty
	holding = false


func set_input(action: String, value: Variant) -> void:
	if action != "hold":
		return
	var down := bool(value)
	if down and not holding and not done:
		_tap()
	holding = down


func _tap() -> void:
	var best := -1
	var best_d := 999.0
	for i in NOTES:
		if float(state[i]) >= 0.0:
			continue
		var d := absf(float(times[i]) - t)
		if d < best_d:
			best_d = d
			best = i
	if best < 0 or best_d > window * 2.0:
		return
	state[best] = 1.0 if best_d <= window else 0.5


func step(dt: float) -> void:
	if done:
		return
	t += dt
	var all_done := true
	for i in NOTES:
		if float(state[i]) < 0.0:
			if t - float(times[i]) > window * 2.0:
				state[i] = 0.0
			else:
				all_done = false
	if all_done:
		done = true
		var total := 0.0
		for s in state:
			total += float(s)
		score = total / float(NOTES)


func snapshot() -> Dictionary:
	var shown: Array = []
	for i in NOTES:
		var ahead := float(times[i]) - t
		if ahead < lead_time and ahead > -window * 2.5:
			shown.append({"p": clampf(1.0 - ahead / lead_time, 0.0, 1.2), "s": float(state[i])})
	var played := 0
	var total := 0.0
	for s in state:
		if float(s) >= 0.0:
			played += 1
			total += float(s)
	return {"kind": "music", "notes": shown, "played": played, "total": NOTES, "good": total, "done": done, "time_left": maxf(0.0, float(times.back()) - t + 0.5),
			"limit": float(times.back()) + 0.5, "caught": done and score >= 0.6, "escaped": done and score < 0.3, "holding": holding}


func result() -> Dictionary:
	return {"score": clampf(score, 0.0, 1.0)}
