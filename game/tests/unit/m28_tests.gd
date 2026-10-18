extends RefCounted
## Tier 2 art: full-body figures, new backgrounds, ending illustrations, the simplified creator and the new interface look.

const PortraitArt = preload("res://scenes/shared/portrait_art.gd")
const StageBackground = preload("res://scenes/shared/stage_background.gd")
const ChibiRig = preload("res://scenes/shared/chibi_rig.gd")
const UiKit = preload("res://scripts/ui/ui_kit.gd")

const FIGURES := ["hero_m", "hero_f", "shen_qinghe", "lu_chenzhou", "bai_yan", "su_dai", "li_shan", "xie_wujiu", "xia_zhi", "xiao_hanchuan",
		"elder", "wanderer", "villager", "bandit", "qian_man", "master_gu", "head_lei", "mask_hui", "mask_xuan", "mask_chi", "guild_master", "leader"]
const BACKGROUNDS := ["valley_dawn", "city_docks", "city_night", "cangwu_night", "yanmen_fort", "penglai_sea", "shrine_night", "riverside_day"]

var check: Callable


func run(check_fn: Callable, _loc: Node) -> void:
	check = check_fn
	for id in FIGURES:
		var t: Texture2D = PortraitArt.figure_for(id)
		check.call(t != null and t.get_height() > 400, "tier2: full-body figure %s exists" % id)
	check.call(PortraitArt.figure_for("hero", "f") == PortraitArt.figure_for("hero_f") and PortraitArt.figure_for("hero", "m") == PortraitArt.figure_for("hero_m"), "tier2: the hero figure follows the gender")
	check.call(PortraitArt.figure_for("isle_yun") == null, "tier2: a character without a figure keeps the code skin")
	for id in BACKGROUNDS:
		var bg := StageBackground.new()
		bg.set_bg(id)
		check.call(bg.has_art(), "tier2: background %s is painted" % id)
		bg.free()
	var alias := StageBackground.new()
	alias.set_bg("yanmen_snow")
	check.call(alias.has_art(), "tier2: yanmen_snow borrows the fort painting")
	alias.free()
	for eid in ["alliance_head", "recluse", "breaker", "undertow", "long_road"]:
		check.call(ResourceLoader.exists("res://art/endings/%s.jpg" % eid), "tier2: ending art %s exists" % eid)
	check.call(PortraitArt.speaker_id("story.speaker.elder", "m") == "elder" and PortraitArt.speaker_id("story.speaker.leader", "m") == "leader" and PortraitArt.speaker_id("story.speaker.villager", "m") == "villager", "tier2: story speakers map to figure ids")
	var rig := ChibiRig.new()
	check.call(rig.use_figure("hero", "f") and rig.sprite != null, "tier2: a rig can switch to a painted figure")
	check.call(not rig.use_figure("isle_yun"), "tier2: a rig falls back when there is no figure")
	rig.free()
	for aid in ["terraces_green", "night_camp", "penglai_cave", "vault_stair", "vault_hall"]:
		var ab := StageBackground.new()
		ab.set_bg(aid)
		check.call(ab.has_art(), "tier2: %s borrows a painting" % aid)
		ab.free()
	var MusicRules = load("res://scripts/domain/music_rules.gd")
	var cat: Dictionary = MusicRules.load_catalog()
	var shared := {}
	for t in cat.tracks:
		check.call(ResourceLoader.exists(str(t.file)), "tier2: music file for %s exists" % str(t.id))
		shared[str(t.file)] = true
	check.call(shared.size() == 8, "tier2: the 20 music slots share the 8 recorded files (%d)" % shared.size())
	var th := UiKit.theme()
	check.call(th.get_stylebox("panel", "PanelContainer") != null and th.has_stylebox("normal", "SealButton"), "tier2: the theme has wuxia panels and seal buttons")
	check.call(UiKit.paper() != null and UiKit.serif() != null, "tier2: paper texture and serif font load")
	var scene: Control = load("res://scenes/menus/hero_creation.tscn").instantiate()
	scene.set_name("creation")
	var host: Node = Engine.get_main_loop().current_scene
	host.add_child(scene)
	check.call(not scene.hair_next.is_visible_in_tree() and not scene.outfit_buttons[0].is_visible_in_tree() and scene.gender_buttons["f"].is_visible_in_tree() and scene.name_edit.is_visible_in_tree(), "tier2: creation offers only name and gender")
	scene.gender_buttons["f"].pressed.emit()
	check.call(scene.preview.sprite == PortraitArt.figure_for("hero_f"), "tier2: the creator preview shows the painted female hero")
	scene.queue_free()
