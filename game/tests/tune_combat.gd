extends SceneTree
const ContentService = preload("res://scripts/services/content_service.gd")
const BattleSetup = preload("res://scripts/domain/combat/battle_setup.gd")
const BattleAI = preload("res://scripts/domain/combat/battle_ai.gd")

func _init() -> void:
	var content := ContentService.new()
	content.load_all()
	for sid in ["training_match", "rescue_battle", "final_crisis"]:
		for party in [[], ["shen_qinghe"], ["shen_qinghe", "lu_chenzhou"], ["bai_yan"]]:
			var line: String = "%s %s:" % [sid, str(party)]
			for s in 6:
				var b: RefCounted = BattleSetup.build(content, sid, s, null, party)
				var g: int = 0
				while b.outcome == "" and g < 400:
					g += 1
					BattleAI.take_turn(b)
				var alive: int = b.alive_units("player").size()
				line += " %s%d(%d)" % [b.outcome.substr(0, 1), b.round_no, alive]
			print(line)
	quit()
