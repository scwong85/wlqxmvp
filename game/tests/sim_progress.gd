extends SceneTree
## Progress simulation: a steady player over 360 slots (training, technique practice, meditation, rest, breakthroughs).
## Prints the week of each realm, final attributes and technique levels. Run: godot --headless -s res://tests/sim_progress.gd
const GameState = preload("res://scripts/domain/game_state.gd")
const ActivityRules = preload("res://scripts/domain/activity_rules.gd")
const RealmRules = preload("res://scripts/domain/realm_rules.gd")
const TechniqueLevels = preload("res://scripts/domain/technique_levels.gd")
const TechniqueRules = preload("res://scripts/domain/technique_rules.gd")


func _initialize() -> void:
	var content: Node = preload("res://scripts/services/content_service.gd").new()
	content.load_all()
	for path in ["xuan_fist", "green_sword", "listening_rain"]:
		var s: RefCounted = GameState.new_game(3)
		s.player.path_id = path
		s.calendar.week = 2
		s.player.stamina = preload("res://scripts/domain/cultivation_rules.gd").max_stamina(s.player)
		var plan := ["training", "technique_practice", "meditation", "training", "technique_practice"]
		var i := 0
		var realm_week := {}
		var guard := 0
		while not s.calendar.finished and guard < 2000:
			guard += 1
			if RealmRules.can_break(s, content).ok:
				var before := int(s.cultivation.realm)
				RealmRules.break_through(s, content)
				realm_week[int(s.cultivation.realm)] = s.calendar.week
				continue
			var act: String = plan[i % plan.size()]
			i += 1
			if s.player.stamina < 12:
				act = "rest"
			var def: Dictionary = content.activity(act)
			var opt := ActivityRules.default_option(def)
			if act == "training" and path != "xuan_fist":
				opt = "iron_body"
			if not ActivityRules.availability(s, def, opt).ok:
				def = content.activity("rest")
				opt = ""
			ActivityRules.perform(s, def, content, opt)
		var attrs: Array = []
		for a in s.player.ATTRS:
			attrs.append(s.player.get_attr(a))
		var techs: Array = []
		for t in s.player.techniques:
			techs.append("%s:%d" % [t, TechniqueLevels.level(s, t)])
		print("SIM %s realm=%d breakthrough_weeks=%s attrs=%s techs=%s progress=%d" % [path, s.cultivation.realm, str(realm_week), str(attrs), str(techs), int(s.cultivation.path_progress.get(path, 0))])
	quit()
