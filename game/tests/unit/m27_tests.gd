extends RefCounted
## M27 tests: translation parity and hygiene for release (both languages complete, placeholders match, no stray text).

const SKIP := ["spike.fallback_only_zh", "ui.language.zh_CN", "ui.language.en", "cult.delta", "sheet.realm_line"]

var check: Callable
var loc: Node


func run(check_fn: Callable, loc_service: Node) -> void:
	check = check_fn
	loc = loc_service
	run_rescue(check_fn)
	run_names(check_fn, loc_service)
	run_realm_text(check_fn, loc_service)
	var re := RegEx.new()
	re.compile("\\{[a-z_0-9]+\\}")
	var cjk := RegEx.new()
	cjk.compile("[\\x{4e00}-\\x{9fff}]")
	var zh: Array = loc.all_keys("zh_CN")
	var en: Array = loc.all_keys("en")
	var missing_en: Array = zh.filter(func(k: String) -> bool: return not loc.has_key(k, "en") and not SKIP.has(k))
	var missing_zh: Array = en.filter(func(k: String) -> bool: return not loc.has_key(k, "zh_CN") and not SKIP.has(k))
	check.call(missing_en.is_empty(), "m27: every Mandarin key has English (%s)" % str(missing_en.slice(0, 3)))
	check.call(missing_zh.is_empty(), "m27: every English key has Mandarin (%s)" % str(missing_zh.slice(0, 3)))
	var ph_bad: Array = []
	var empty: Array = []
	var cjk_in_en: Array = []
	for k in zh:
		if not loc.has_key(k, "en"):
			continue
		var a := ""
		var b := ""
		for m in re.search_all(loc._tables["zh_CN"][k]):
			a += m.get_string()
		for m in re.search_all(loc._tables["en"][k]):
			b += m.get_string()
		var pa: Array = Array(a.split("}")); pa.sort()
		var pb: Array = Array(b.split("}")); pb.sort()
		if pa != pb:
			ph_bad.append(k)
		if str(loc._tables["zh_CN"][k]).strip_edges() == "" or str(loc._tables["en"][k]).strip_edges() == "":
			empty.append(k)
		if cjk.search(loc._tables["en"][k]) != null and not SKIP.has(k):
			cjk_in_en.append(k)
	check.call(ph_bad.is_empty(), "m27: placeholders match in both languages (%s)" % str(ph_bad.slice(0, 3)))
	check.call(empty.is_empty(), "m27: no empty text (%s)" % str(empty.slice(0, 3)))
	check.call(cjk_in_en.is_empty(), "m27: no Chinese text left in the English table (%s)" % str(cjk_in_en.slice(0, 3)))


## Regression: the week-3 rescue fight must be winnable by a newly started hero with no or one companion
## (it was lost 20 of 20 times because the villager had 45 hp).
func run_rescue(check_fn: Callable) -> void:
	var BattleSetup = preload("res://scripts/domain/combat/battle_setup.gd")
	var BattleAI = preload("res://scripts/domain/combat/battle_ai.gd")
	var GameState = preload("res://scripts/domain/game_state.gd")
	var ContentService = preload("res://scripts/services/content_service.gd")
	var content: Node = ContentService.new()
	content.load_all()
	for party in [[], ["shen_qinghe"]]:
		var wins := 0
		for sd in 12:
			var b = BattleSetup.build(content, "rescue_battle", sd, GameState.new_game(), party)
			var g := 0
			while b.outcome == "" and g < 400:
				g += 1
				BattleAI.take_turn(b)
			if b.outcome == "victory":
				wins += 1
		check_fn.call(wins >= 10, "m27: the rescue fight is winnable with party %s (%d/12)" % [str(party), wins])
	content.free()


## Every reward id shown to the player (items, battles, clues, buffs, resources) has a name in both languages.
func run_names(check_fn: Callable, loc_node: Node) -> void:
	var prefix := {"item": "item.", "battle": "battle.", "clue": "clue.", "buff": "buff.", "resource": "resource."}
	var missing: Array = []
	var stack: Array = []
	for f in ["combat/scenarios.json", "world/areas.json", "world/events.json", "world/event_dialogues.json", "story/dialogues.json", "activities/activities.json"]:
		var path: String = "res://content/" + str(f)
		if not FileAccess.file_exists(path):
			continue
		var j := JSON.new()
		if j.parse(FileAccess.get_file_as_string(path)) == OK:
			stack.append(j.data)
	while not stack.is_empty():
		var o: Variant = stack.pop_back()
		if o is Dictionary:
			var t: String = str(o.get("type", ""))
			if prefix.has(t) and o.has("id") and (o.has("amount") or t == "battle") and not str(o.id).begins_with("$"):
				for lang in ["en", "zh_CN"]:
					if not loc_node.has_key(prefix[t] + str(o.id), lang):
						missing.append("%s:%s" % [lang, prefix[t] + str(o.id)])
			stack.append_array(o.values())
		elif o is Array:
			stack.append_array(o)
	check_fn.call(missing.is_empty(), "m27: every reward and battle name exists in both languages (%s)" % str(missing.slice(0, 4)))


## The realm requirement texts are filled with {realm} by the code; any other placeholder would show raw.
func run_realm_text(check_fn: Callable, loc_node: Node) -> void:
	for lang in ["en", "zh_CN"]:
		for k in ["tree.realm", "manual.realm", "equip.realm"]:
			check_fn.call(loc_node._tables[lang][k].contains("{realm}") and not loc_node._tables[lang][k].contains("{name}"), "m27: %s uses the {realm} placeholder in %s" % [k, lang])
