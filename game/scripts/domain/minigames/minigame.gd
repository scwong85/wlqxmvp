extends RefCounted
## Minigame interface. A minigame is pure logic (no nodes): it is started with params and a seed, fed input and fixed
## time steps, and ends with a result {score 0..1, detail}. Views draw `snapshot()`. Because it is deterministic for a
## seed and an input script, tests replay it exactly.

var done: bool = false
var score: float = 0.0


## Start (or restart) with {difficulty: 0..2, ...} and a seed.
func start(_params: Dictionary, _seed: int) -> void:
	done = false
	score = 0.0


## Input is named, so touch, mouse and keyboard all map onto the same actions (e.g. "hold": true/false).
func set_input(_action: String, _value: Variant) -> void:
	pass


## Advance by dt seconds (callers use fixed steps).
func step(_dt: float) -> void:
	pass


## What a view needs to draw right now.
func snapshot() -> Dictionary:
	return {}


func result() -> Dictionary:
	return {"score": clampf(score, 0.0, 1.0)}
