extends SceneTree
## Year 1 battle balance: each Year 1 scenario, fought by the auto-AI with a hero at the expected realm and 0 to 2 companions.
## Run: godot --headless --path game -s res://tests/sim_year1.gd
const ContentService = preload("res://scripts/services/content_service.gd")
const BattleSetup = preload("res://scripts/domain/combat/battle_setup.gd")
const BattleAI = preload("res://scripts/domain/combat/battle_ai.gd")
const GameState = preload("res://scripts/domain/game_state.gd")
const PartySystem = preload("res://scripts/domain/party_system.gd")

const RUNS := 60
var RATIO := 0.7
# scenario -> [expected realm, companions]
const PLAN := {"masked_escort": [1, ["shen_qinghe"]], "dock_scam": [2, ["shen_qinghe"]], "caravan_escort": [2, ["lu_chenzhou"]], "guild_night": [2, ["lu_chenzhou", "su_dai"]],
	"xie_duel": [3, ["bai_yan"]], "cw_bout_1": [3, ["bai_yan"]], "cw_bout_2": [3, ["bai_yan", "li_shan"]], "cw_bout_3": [3, ["bai_yan"]], "q4_ambush": [3, ["lu_chenzhou", "xie_wujiu"]],
	"y2_xia_catch": [3, ["bai_yan"]], "y2_patrol": [3, ["shen_qinghe"]], "y2_barge_riot": [3, ["lu_chenzhou", "xia_zhi"]],
	"y2_xiao_spar": [3, ["bai_yan"]], "y2_snow_pass": [4, ["xiao_hanchuan"]], "y2_pass_battle": [4, ["xiao_hanchuan", "li_shan"]],
	"y2_hermit_trial": [4, ["xiao_hanchuan"]], "y2_sea_ambush": [4, ["xiao_hanchuan", "xia_zhi"]], "y2_harbour_brawl": [4, ["su_dai"]],
	"y2_public_proof": [4, ["xie_wujiu"]], "y2_break_ranks": [4, ["xiao_hanchuan", "li_shan"]], "y2_rescue": [5, ["xia_zhi", "lu_chenzhou"]],
	"y3_guild_hall": [5, ["xia_zhi", "lu_chenzhou"]], "y3_chi_duel": [5, ["xie_wujiu", "shen_qinghe"]], "y3_border_defence": [5, ["xiao_hanchuan", "li_shan"]]}
const CAPS := {1: 16, 2: 24, 3: 34, 4: 46, 5: 60}


func _init() -> void:
	for a in OS.get_cmdline_user_args():
		RATIO = float(a)
	var content: Node = ContentService.new()
	content.load_all()
	var out := "| Scenario | Realm | Party | Win % | Avg rounds |\n|---|---|---|---|---|\n"
	for sid in PLAN:
		var realm: int = PLAN[sid][0]
		var comps: Array = PLAN[sid][1]
		var wins := 0
		var total_rounds := 0
		for i in RUNS:
			var st: RefCounted = GameState.new_game(1)
			st.cultivation.realm = realm
			st.player.attr_cap = CAPS[realm]
			var pts: int = int(CAPS[realm] * RATIO)
			for a in ["power", "body", "agility", "spirit"]:
				st.player.add_attr(a, pts)
			st.player.attr_cap = CAPS[realm]
			st.player.learn("fist_wave")
			st.player.learn("fist_counter")
			for c in comps:
				st.relationships.set_status(c, "joined")
				st.relationships.scores[c] = 12
			PartySystem.set_active(st, comps[0])
			if comps.size() > 1:
				st.relationships.second = comps[1]
			var b: RefCounted = BattleSetup.build(content, sid, 2000 + i, st, comps)
			var g := 0
			while b.outcome == "" and g < 500:
				g += 1
				BattleAI.take_turn(b)
			total_rounds += b.round_no
			if b.outcome == "victory":
				wins += 1
		out += "| %s | %d | %s | %d | %.1f |\n" % [sid, realm, ",".join(comps), wins * 100 / RUNS, float(total_rounds) / RUNS]
	print(out)
	quit()
