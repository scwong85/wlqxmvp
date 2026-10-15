extends SceneTree
## Balance simulation: 100 seeded auto-played battles per scenario and cultivation build, companion rotating
## with the seed. Writes a Markdown table. Run:
##   godot --headless --path game -s res://tests/sim_balance.gd -- docs_out_path
const ContentService = preload("res://scripts/services/content_service.gd")
const BattleSetup = preload("res://scripts/domain/combat/battle_setup.gd")
const BattleAI = preload("res://scripts/domain/combat/battle_ai.gd")
const GameState = preload("res://scripts/domain/game_state.gd")
const PartySystem = preload("res://scripts/domain/party_system.gd")

const RUNS := 100
const COMPANIONS := ["shen_qinghe", "lu_chenzhou", "bai_yan"]
# Attribute growth the hero can really have: the week has 14 slots worth 1-3 points each, so about 5 points by the
# Bamboo Pass fight, 9 by day 4 and 20 by the end of day 7.
const STAGE_POINTS := {"training_match": 0, "bandit_scouts": 5, "rescue_battle": 9, "final_crisis": 20}
const STAGE_TECHS := {"training_match": 0, "bandit_scouts": 1, "rescue_battle": 1, "final_crisis": 2}
const BUILDS := {
	"fist": {"weights": {"power": 40, "body": 35, "spirit": 15, "agility": 10}, "techs": ["fist_wave", "fist_counter"]},
	"sword": {"weights": {"agility": 40, "power": 30, "insight": 15, "body": 15}, "techs": ["sword_flash", "sword_follow"]},
	"rain": {"weights": {"spirit": 35, "insight": 30, "body": 20, "power": 15}, "techs": ["rain_heal", "rain_calm"]},
	"even": {"weights": {"power": 20, "body": 20, "agility": 20, "insight": 20, "spirit": 20}, "techs": ["sword_flash", "fist_wave"]},
}


func _state(build: String, scenario: String, companion: String) -> RefCounted:
	var st: RefCounted = GameState.new_game(1)
	var b: Dictionary = BUILDS[build]
	var points: int = STAGE_POINTS[scenario]
	for attr in b.weights:
		st.player.add_attr(attr, int(round(points * b.weights[attr] / 100.0)))
	for i in mini(int(STAGE_TECHS[scenario]), b.techs.size()):
		st.player.learn(b.techs[i])
	st.relationships.set_status(companion, "joined")
	st.relationships.scores[companion] = 9
	PartySystem.set_active(st, companion)
	return st


func _init() -> void:
	var out_path := ""
	for a in OS.get_cmdline_user_args():
		out_path = a
	var content: Node = ContentService.new()
	content.load_all()
	var rows: Array = []
	var flagged: Array = []
	var total_ms := Time.get_ticks_msec()
	for sid in ["training_match", "bandit_scouts", "rescue_battle", "final_crisis"]:
		for build in BUILDS:
			var wins := 0
			var rounds: Array = []
			var in_range := 0
			for i in RUNS:
				var comp: String = COMPANIONS[i % 3]
				var st := _state(build, sid, comp)
				var b: RefCounted = BattleSetup.build(content, sid, 1000 + i, st, [comp])
				var g := 0
				while b.outcome == "" and g < 400:
					g += 1
					BattleAI.take_turn(b)
				var fought: int = b.round_no - 1 if (b.outcome_reason == "survived" or b.outcome_reason == "out_of_time") else b.round_no
				rounds.append(fought)
				if b.outcome == "victory":
					wins += 1
				if fought >= 3 and fought <= 7:
					in_range += 1
			rounds.sort()
			var sum := 0
			for r in rounds:
				sum += r
			var row := {"scenario": sid, "build": build, "win": wins, "min": rounds[0], "avg": float(sum) / RUNS, "max": rounds[-1], "in_range": in_range}
			rows.append(row)
			var lo: int = {"training_match": 90, "bandit_scouts": 70, "rescue_battle": 55, "final_crisis": 55}[sid]
			var hi: int = {"training_match": 100, "bandit_scouts": 100, "rescue_battle": 92, "final_crisis": 100}[sid]
			if in_range < 80 or wins < lo or wins > hi:
				flagged.append(row)
	var md := "| Scenario | Build | Win % | Rounds min / avg / max | In 3-7 rounds % |\n|---|---|---|---|---|\n"
	for r in rows:
		md += "| %s | %s | %d | %d / %.1f / %d | %d |\n" % [r.scenario, r.build, r.win, r.min, r.avg, r.max, r.in_range]
	print(md)
	print("FLAGGED %d of %d cells" % [flagged.size(), rows.size()])
	for f in flagged:
		print("  flagged: %s %s win=%d in_range=%d" % [f.scenario, f.build, f.win, f.in_range])
	print("SIM_MS ", Time.get_ticks_msec() - total_ms)
	if out_path != "":
		var f := FileAccess.open(out_path, FileAccess.WRITE)
		f.store_string(md)
		f.close()
	quit()
