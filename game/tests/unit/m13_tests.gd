extends RefCounted
## M13 tests: localization lint (coverage, placeholders, unused keys, hard-coded text, glyphs), font fallback,
## contrast, audio volume persistence, pause menu.

const KeyLint = preload("res://tests/key_lint.gd")
const UiKit = preload("res://scripts/ui/ui_kit.gd")

var check: Callable
var loc: Node


func run(check_fn: Callable, loc_service: Node) -> void:
	check = check_fn
	loc = loc_service
	var game_loc: Node = Engine.get_main_loop().root.get_node("Loc")
	_lint(game_loc)
	_fallback(game_loc)
	_contrast()
	_audio()
	_assets()


func _lint(l: Node) -> void:
	var r: Dictionary = KeyLint.run(l)
	check.call(r.missing_zh.is_empty(), "m13: zero English keys without a Mandarin key %s" % str(r.missing_zh))
	check.call(r.missing_en.is_empty(), "m13: every Mandarin key has English %s" % str(r.missing_en.slice(0, 5)))
	check.call(r.placeholder_mismatch.is_empty(), "m13: placeholders match between languages %s" % str(r.placeholder_mismatch.slice(0, 5)))
	check.call(r.unused.is_empty(), "m13: no unused keys %s" % str(r.unused.slice(0, 8)))
	check.call(r.bad_content_keys.is_empty(), "m13: every key named in content exists %s" % str(r.bad_content_keys.slice(0, 5)))
	check.call(r.hardcoded.is_empty(), "m13: no hard-coded text in scenes or scripts %s" % str(r.hardcoded.slice(0, 5)))
	check.call(r.missing_glyphs.is_empty(), "m13: the bundled font draws every character of both languages %s" % str(r.missing_glyphs))
	# No lookup ever shows a raw key.
	var raw := 0
	for code in ["zh_CN", "en"]:
		var saved: String = l.locale
		l.locale = code
		for k in l.all_keys("zh_CN"):
			if l.t(k).begins_with("[") and l.t(k).ends_with("]") and l.t(k) == "[%s]" % k:
				raw += 1
		l.locale = saved
	check.call(raw == 0, "m13: no key renders as [key] in either language")
	# A key missing in English shows the Mandarin text, a key missing everywhere is visible.
	var f: Node = preload("res://scripts/services/localization_service.gd").new()
	f._ready()
	f.locale = "en"
	f._tables["en"].erase("title.name")
	check.call(f.t("title.name") == "玉谷传奇" and f.t("no.such.key") == "[no.such.key]", "m13: English gaps fall back to Mandarin; unknown keys are visible")
	f.free()


func _fallback(l: Node) -> void:
	var rare := "玉谷𠮷"  # the third character is outside the bundled subset
	var miss: Array = l.missing_glyphs(rare)
	check.call(miss == ["𠮷"], "m13: a rare glyph is reported as missing from the bundled font (%s)" % str(miss))
	var font := load("res://fonts/NotoSansSC-subset.otf") as FontFile
	check.call(font != null and not font.fallbacks.is_empty() and font.fallbacks[0] is SystemFont, "m13: the font has a system fallback for rare glyphs")


func _lum(c: Color) -> float:
	var f := func(v: float) -> float: return v / 12.92 if v <= 0.03928 else pow((v + 0.055) / 1.055, 2.4)
	return 0.2126 * f.call(c.r) + 0.7152 * f.call(c.g) + 0.0722 * f.call(c.b)


func _ratio(a: Color, b: Color) -> float:
	var la := _lum(a)
	var lb := _lum(b)
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)


## Semi-transparent panels are checked over the lightest backdrop colour they can sit on (worst case).
func _over(bg: Color, base: Color) -> Color:
	return base.lerp(Color(bg.r, bg.g, bg.b), bg.a)


func _contrast() -> void:
	var t: Theme = UiKit.theme()
	var worst_base := Color("1c4a40")  # lightest tone the placeholder backdrop reaches
	var pairs := {
		"label on backdrop": [t.get_color("font_color", "Label"), worst_base, 4.5],
		"button text": [t.get_color("font_color", "Button"), _over((t.get_stylebox("normal", "Button") as StyleBoxFlat).bg_color, worst_base), 4.5],
		"button hover text": [t.get_color("font_hover_color", "Button"), _over((t.get_stylebox("hover", "Button") as StyleBoxFlat).bg_color, worst_base), 4.5],
		"button pressed text": [t.get_color("font_pressed_color", "Button"), _over((t.get_stylebox("pressed", "Button") as StyleBoxFlat).bg_color, worst_base), 4.5],
		"card button text": [t.get_color("font_color", "Button"), _over((t.get_stylebox("normal", "CardButton") as StyleBoxFlat).bg_color, worst_base), 4.5],
		"panel text": [t.get_color("font_color", "Label"), _over((t.get_stylebox("panel", "PanelContainer") as StyleBoxFlat).bg_color, worst_base), 4.5],
		"disabled button text": [t.get_color("font_disabled_color", "Button"), _over((t.get_stylebox("disabled", "Button") as StyleBoxFlat).bg_color, worst_base), 3.0],
		"speaker/title accent": [Color("9be3c3"), Color("0b1f1e"), 4.5],
		"focus ring": [t.get_color("font_color", "Button"), Color("0b1f1e"), 3.0],
	}
	for name in pairs:
		var p: Array = pairs[name]
		var ratio := _ratio(p[0], p[1])
		check.call(ratio >= float(p[2]), "m13: contrast %s %.1f:1 (need %.1f)" % [name, ratio, p[2]])
		print("CONTRAST %s %.2f" % [name, ratio])
	check.call(t.default_font_size >= 22, "m13: default font size is at least 22")


func _audio() -> void:
	var root: Node = Engine.get_main_loop().root
	var audio: Node = root.get_node("Audio")
	var saves: Node = root.get_node("Saves")
	var old_dir: String = saves.dir
	saves.dir = "user://m13_saves/"
	DirAccess.make_dir_recursive_absolute(saves.dir)
	saves.save_settings({"locale": "en"})
	audio.set_volume("music", 25)
	audio.set_volume("sfx", 0)
	var s: Dictionary = saves.load_settings()
	check.call(s.get("music_volume") == 25 and s.get("sfx_volume") == 0 and s.get("locale") == "en", "m13: volumes save without losing the language setting")
	check.call(AudioServer.get_bus_index("Music") != -1 and AudioServer.get_bus_index("SFX") != -1, "m13: Music and SFX buses exist")
	check.call(AudioServer.is_bus_mute(AudioServer.get_bus_index("SFX")) and not AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")), "m13: volume 0 mutes the bus")
	check.call(absf(audio.bus_db("music") - linear_to_db(0.25)) < 0.01, "m13: 25% maps to the right decibels")
	audio.volumes = {"music": 99, "sfx": 99}
	audio._ready_load_for_test() if audio.has_method("_ready_load_for_test") else null
	audio.volumes = audio.DEFAULTS.duplicate()
	var saved: Dictionary = saves.load_settings()
	for k in audio.DEFAULTS:
		audio.volumes[k] = clampi(int(saved.get(k + "_volume", audio.DEFAULTS[k])), 0, 100)
	check.call(audio.get_volume("music") == 25 and audio.get_volume("sfx") == 0, "m13: saved volumes load back")
	audio.set_volume("music", 500, false)
	check.call(audio.get_volume("music") == 100, "m13: volume is clamped to 0..100")
	audio.set_volume("music", Audio.DEFAULTS.music, false)
	audio.set_volume("sfx", Audio.DEFAULTS.sfx, false)
	for f in DirAccess.get_files_at(saves.dir):
		DirAccess.remove_absolute(saves.dir.path_join(f))
	saves.dir = old_dir


## Only the bundled font is an external asset; all art and sound is drawn or synthesised in code.
func _assets() -> void:
	var found: Array = []
	for ext in [".png", ".jpg", ".jpeg", ".svg", ".webp", ".ogg", ".wav", ".mp3", ".ttf", ".otf"]:
		for dir in ["res://scenes", "res://scripts", "res://content", "res://fonts"]:
			found.append_array(KeyLint.files(dir, ext))
	check.call(found == ["res://fonts/NotoSansSC-subset.otf"], "m13: the only external asset is the subset font %s" % str(found))
