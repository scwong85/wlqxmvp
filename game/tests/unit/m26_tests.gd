extends RefCounted
## M26 tests: the five endings (table and priority), the epilogue composer (sections, companions, text in both languages).

const ArcRules = preload("res://scripts/domain/arc_rules.gd")
const EndingRules = preload("res://scripts/domain/ending_rules.gd")
const EpilogueRules = preload("res://scripts/domain/epilogue_rules.gd")
const ContentService = preload("res://scripts/services/content_service.gd")

const CIDS := ["shen_qinghe", "lu_chenzhou", "bai_yan", "su_dai", "li_shan", "xie_wujiu", "xia_zhi", "xiao_hanchuan"]

var check: Callable
var loc: Node
var content: Node
var game: Node


func run(check_fn: Callable, loc_service: Node) -> void:
	check = check_fn
	loc = loc_service
	content = ContentService.new()
	content.load_all()
	game = Engine.get_main_loop().root.get_node("Game")
	_data()
	_table()
	_composer()
	_text()
	content.free()


func _state(flags: Array, outcomes: Dictionary = {}, realm: int = 3) -> RefCounted:
	game.new_game(26)
	var s: RefCounted = game.state
	for c in CIDS:
		ArcRules.set_outcome(s, c, str(outcomes.get(c, "redeemed")))
		ArcRules.set_bond(s, c, "friend")
	for f in flags:
		s.relationships.set_flag(str(f))
	s.cultivation.realm = realm
	return s


func _has_key(k: String) -> bool:
	return loc.has_key(k, "en") and loc.has_key(k, "zh_CN")


func _data() -> void:
	check.call(content.endings.size() == 5, "m26: five endings")
	var ids: Array = content.endings.map(func(e: Dictionary) -> String: return str(e.id))
	check.call(ids == ["alliance_head", "recluse", "breaker", "undertow", "long_road"], "m26: the endings are in priority order (%s)" % str(ids))
	check.call(content.epilogue.snippets.size() >= 90, "m26: at least 90 epilogue snippets (%d)" % content.epilogue.snippets.size())
	for c in CIDS:
		for o in ["redeemed", "alternate", "lost"]:
			check.call(content.epilogue.snippets.any(func(s: Dictionary) -> bool: return s.get("companion", "") == c and s.requires.get("outcome", "") == o), "m26: %s has an %s line" % [c, o])
		for b in ArcRules.BONDS:
			check.call(content.epilogue.snippets.any(func(s: Dictionary) -> bool: return s.get("companion", "") == c and s.requires.get("bond", "") == b), "m26: %s has a %s line" % [c, b])
	check.call(content.validate(_has_key).is_empty(), "m26: content validates (%s)" % str(content.validate(_has_key)))


func _table() -> void:
	var lost3 := {"shen_qinghe": "lost", "lu_chenzhou": "lost", "bai_yan": "lost"}
	var cases := [
		["alliance_head", ["finale_seat", "pledge_orthodox"], {}, 3],
		["alliance_head", ["finale_seat", "pledge_free"], {"shen_qinghe": "lost", "lu_chenzhou": "alternate"}, 3],
		["long_road", ["finale_seat", "pledge_orthodox"], lost3, 3],
		["long_road", ["finale_seat"], {}, 3],
		["long_road", ["finale_seat", "pledge_trade"], {}, 2],
		["recluse", ["finale_refuse", "valley_kept"], {}, 4],
		["long_road", ["finale_refuse", "valley_kept"], {}, 3],
		["long_road", ["finale_refuse"], {}, 5],
		["breaker", ["finale_break"], {"xia_zhi": "alternate", "bai_yan": "redeemed"}, 1],
		["breaker", ["finale_break"], {"bai_yan": "alternate", "xia_zhi": "redeemed"}, 1],
		["long_road", ["finale_break"], {"bai_yan": "alternate", "xia_zhi": "alternate"}, 6],
		["undertow", ["finale_gate", "xuan_pact"], {}, 0],
		["undertow", ["finale_gate", "arcout_xia_zhi_lost"], {"xia_zhi": "lost"}, 0],
		["undertow", ["finale_gate", "arcout_xia_zhi_lost"], {}, 0],
		["long_road", ["finale_gate"], {}, 5],
		["long_road", ["finale_walk"], {}, 6],
		["long_road", [], {}, 6],
	]
	var reached := {}
	for c in cases:
		var s := _state(c[1], c[2], c[3])
		var got := EndingRules.evaluate(s, content)
		reached[got] = true
		check.call(got == c[0], "m26: ending %s (got %s) for %s %s realm %d" % [c[0], got, str(c[1]), str(c[2]), c[3]])
	check.call(reached.size() == 5, "m26: every ending is reached by the table")
	# a finale flag set that two endings could match: priority wins (seat before break)
	var both := _state(["finale_seat", "finale_break", "pledge_orthodox"], {"bai_yan": "redeemed"}, 3)
	check.call(EndingRules.evaluate(both, content) == "alliance_head", "m26: the first matching ending wins")


func _composer() -> void:
	for id in ["alliance_head", "recluse", "breaker", "undertow", "long_road"]:
		var s := _state(["pledge_orthodox", "valley_kept", "faction_pavilion"], {"xia_zhi": "alternate"}, 4)
		var paras: Array = EpilogueRules.compose(s, content, id)
		var comps: int = paras.filter(func(p: Dictionary) -> bool: return p.section == "comp").size()
		check.call(comps == 8, "m26: %s epilogue has a paragraph for each of the 8 companions (%d)" % [id, comps])
		check.call(paras.any(func(p: Dictionary) -> bool: return p.section == "image"), "m26: %s epilogue ends with an image line" % id)
		check.call(paras.back().section == "image", "m26: the image line is last")
		check.call(paras.any(func(p: Dictionary) -> bool: return p.section == "hero_realm"), "m26: %s epilogue has a realm line" % id)
	# the "why" line appears only for the long road, and matches the choice
	var lr := EpilogueRules.compose(_state(["finale_seat"], {"shen_qinghe": "lost", "lu_chenzhou": "lost", "bai_yan": "lost"}), content, "long_road")
	check.call(lr[0].section == "why" and lr[0].keys[0] == "epi.why_seat", "m26: the long road explains the seat that did not hold")
	var ok := EpilogueRules.compose(_state(["finale_seat", "pledge_free"]), content, "alliance_head")
	check.call(not ok.any(func(p: Dictionary) -> bool: return p.section == "why"), "m26: other endings have no explanation line")
	# unmet companions: no paragraph, one generic line
	game.new_game(27)
	var fresh: RefCounted = game.state
	var p0 := EpilogueRules.compose(fresh, content, "long_road")
	check.call(p0.filter(func(p: Dictionary) -> bool: return p.section == "comp").is_empty() and p0.any(func(p: Dictionary) -> bool: return p.section == "comp_unmet"), "m26: companions never met give one generic line")
	# faction, hometown and wealth lines follow the state
	var s2 := _state(["faction_couriers", "elder_fallen"])
	s2.resources.add("coins", 2000)
	var keys: Array = []
	for p in EpilogueRules.compose(s2, content, "long_road"):
		keys.append_array(p.keys)
	check.call(keys.has("epi.faction_couriers") and keys.has("epi.valley_elder_fell") and keys.has("epi.wealth_rich"), "m26: faction, hometown and wealth lines follow the state")
	# deterministic
	check.call(JSON.stringify(EpilogueRules.compose(s2, content, "long_road")) == JSON.stringify(EpilogueRules.compose(s2, content, "long_road")), "m26: composing twice gives the same epilogue")


func _text() -> void:
	var s := _state(["finale_seat", "pledge_orthodox", "valley_kept"], {}, 4)
	var paras := EpilogueRules.compose(s, content, "alliance_head")
	for lang in ["en", "zh_CN"]:
		loc.set_locale(lang)
		var bad := 0
		var total := 0
		for p in paras:
			for k in p.keys:
				var t: String = loc.t(str(k), p.params)
				total += 1
				if t.begins_with("[") or "{" in t or t == "":
					bad += 1
		check.call(bad == 0 and total > 10, "m26: epilogue text resolves fully in %s (%d lines, %d bad)" % [lang, total, bad])
		var lens := 0
		for sn in content.epilogue.snippets:
			lens = maxi(lens, loc.t(str(sn.key)).length())
		check.call(lens <= 130, "m26: snippets stay short in %s (longest %d)" % [lang, lens])
	loc.set_locale("zh_CN")
