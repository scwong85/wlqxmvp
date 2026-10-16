extends RefCounted
## Painted art: backgrounds with a file use it, the rest keep the code-drawn placeholder.

const StageBackground = preload("res://scenes/shared/stage_background.gd")

var check: Callable


func run(check_fn: Callable, _loc: Node) -> void:
	check = check_fn
	for id in ["valley_day", "village_dusk", "city_market", "cangwu_day"]:
		var bg := StageBackground.new()
		bg.set_bg(id)
		check.call(bg.has_art(), "art: %s uses the painted background" % id)
		bg.free()
	var plain := StageBackground.new()
	plain.set_bg("bamboo_mist")
	check.call(not plain.has_art(), "art: a background without a file keeps the placeholder")
	plain.free()
	check.call(ResourceLoader.exists("res://art/title_key.jpg"), "art: the title key art is present")
	var PortraitArt = load("res://scenes/shared/portrait_art.gd")
	for cid in ["hero_m", "hero_f", "shen_qinghe", "lu_chenzhou", "bai_yan", "su_dai", "li_shan", "xie_wujiu", "xia_zhi", "xiao_hanchuan"]:
		for face in ["neutral", "happy", "sad", "angry", "surprised"]:
			check.call(PortraitArt.texture_for(cid, face) != null, "art: portrait %s/%s exists" % [cid, face])
	check.call(PortraitArt.texture_for("nobody") == null, "art: an unknown character has no portrait")
	check.call(PortraitArt.speaker_id("npc.su_dai", "m") == "su_dai" and PortraitArt.speaker_id("world.speaker.hero", "f") == "hero_f" and PortraitArt.speaker_id("world.speaker.hero", "m") == "hero_m" and PortraitArt.speaker_id("world.speaker.narrator", "m") == "", "art: speaker keys map to portrait ids")
	for id in ["marsh_day", "ferry_dusk"]:
		var bg := StageBackground.new()
		bg.set_bg(id)
		check.call(bg.has_art(), "art: %s uses the painted background" % id)
		bg.free()
