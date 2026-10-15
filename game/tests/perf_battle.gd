extends SceneTree
## godot --headless --path game -s res://tests/perf_battle.gd
## Script costs of the battle screen without rendering: time to build the scene, time per enemy turn, and the
## engine's own per-second process monitor (steady state). Rendering cost needs a browser or device (web_smoke.py).
const BattleAI = preload("res://scripts/domain/combat/battle_ai.gd")
const BattleSetup = preload("res://scripts/domain/combat/battle_setup.gd")
var frames := 0
var t0 := 0
var build_ms := 0.0
var monitor: Array[float] = []


func _initialize() -> void:
	root.get_node("Game").battle_instant = true
	root.get_node("Game").new_game(3)
	root.get_node("Game").start_battle("training_match", "practice")


func _process(_d: float) -> bool:
	frames += 1
	if frames == 1:
		t0 = Time.get_ticks_usec()
		root.get_node("Router").goto("battle")
	elif frames == 3:
		build_ms = (Time.get_ticks_usec() - t0) / 1000.0
	elif frames > 60:
		monitor.append(Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0)
	if frames == 360:
		var b: RefCounted = BattleSetup.build(root.get_node("Content"), "final_crisis", 5, null, [])
		var turns := 0
		var t1 := Time.get_ticks_usec()
		while b.outcome == "" and turns < 200:
			BattleAI.take_turn(b)
			turns += 1
		var turn_ms := (Time.get_ticks_usec() - t1) / 1000.0 / maxi(1, turns)
		monitor.sort()
		print("PERF_BATTLE scene_build_ms=%.1f ai_turn_ms=%.2f (%d turns) steady_process_ms_median=%.2f max=%.2f nodes=%d" % [build_ms, turn_ms, turns, monitor[monitor.size() / 2], monitor[-1], int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))])
		quit()
	return false
