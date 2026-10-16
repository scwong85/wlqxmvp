extends RefCounted
## M23b tests: the music catalog (every file exists, every mapping points at a track) and the track rules.

const MusicRules = preload("res://scripts/domain/music_rules.gd")
const StageRules = preload("res://scripts/domain/stage_rules.gd")
const ContentService = preload("res://scripts/services/content_service.gd")

var check: Callable


func run(check_fn: Callable, _loc: Node) -> void:
	check = check_fn
	var cat: Dictionary = MusicRules.load_catalog()
	check.call(not cat.is_empty() and cat.tracks.size() >= 18, "m23b: the music catalog loads with its tracks")
	var ids := {}
	for t in cat.tracks:
		ids[str(t.id)] = true
		check.call(ResourceLoader.exists(str(t.file)), "m23b: file exists for %s" % str(t.id))
	var rules: Dictionary = cat.rules
	var all_targets: Array = []
	for group in ["scenes", "regions", "backgrounds", "events"]:
		for k in rules[group]:
			all_targets.append(str(rules[group][k]))
	all_targets.append_array([str(rules.fallback), str(rules.battles.default), str(rules.stings.victory), str(rules.stings.defeat), "boss_theme", "duel_theme"])
	check.call(all_targets.all(func(t: String) -> bool: return ids.has(t)), "m23b: every mapping points at a catalog track")
	var content: Node = ContentService.new()
	content.load_all()
	check.call(StageRules.BACKGROUNDS.all(func(b: String) -> bool: return rules.backgrounds.has(b)), "m23b: every stage background has a track")
	var regions := {}
	for a in content.areas:
		regions[str(a.region)] = true
	check.call(regions.keys().all(func(r: String) -> bool: return rules.regions.has(r)), "m23b: every region in use has a theme")
	check.call(rules.events.keys().all(func(e: String) -> bool: return not content.event(e).is_empty()), "m23b: every event override names a real event")
	for sid in rules.battles.boss + rules.battles.duel:
		check.call(not content.scenario(str(sid)).is_empty(), "m23b: battle mapping %s is a real scenario" % str(sid))
	content.free()
	# Rules
	check.call(MusicRules.track_for({"scene": "title"}, cat) == "title_theme", "m23b: the title plays the title theme")
	check.call(MusicRules.track_for({"scene": "cultivation"}, cat) == "practice_theme", "m23b: practice has its own theme")
	check.call(MusicRules.track_for({"scene": "exploration", "region": "linjiang"}, cat) == "linjiang_theme", "m23b: exploring follows the region")
	check.call(MusicRules.track_for({"scene": "dialogue", "bg": "marsh_night"}, cat) == "mystery_theme", "m23b: a dialogue follows its background")
	check.call(MusicRules.track_for({"scene": "dialogue", "bg": "cangwu_day", "event_id": "q3_theft"}, cat) == "sorrow_theme", "m23b: an event override wins over the background")
	check.call(MusicRules.track_for({"scene": "battle", "scenario_id": "q4_ambush"}, cat) == "boss_theme", "m23b: the ambush plays boss music")
	check.call(MusicRules.track_for({"scene": "battle", "scenario_id": "xie_duel"}, cat) == "duel_theme", "m23b: a duel plays duel music")
	check.call(MusicRules.track_for({"scene": "battle", "scenario_id": "bandit_scouts"}, cat) == "battle_theme", "m23b: other fights play battle music")
	check.call(MusicRules.track_for({"scene": "nowhere"}, cat) == "valley_theme", "m23b: unknown contexts fall back")
