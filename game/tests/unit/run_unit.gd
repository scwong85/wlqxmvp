extends Node
## Unit tests: run with  godot --headless --path game res://tests/unit/run_unit.tscn
## Exit code 0 = all passed. Prints UNIT_OK or UNIT_FAIL.

const LocService = preload("res://scripts/services/localization_service.gd")

var _fails: Array[String] = []
var _count := 0


func _check(cond: bool, label: String) -> void:
	_count += 1
	if not cond:
		_fails.append(label)
		print("  FAIL: ", label)


func _fresh_loc() -> Node:
	var s: Node = LocService.new()
	s._ready()
	return s


func _ready() -> void:
	_test_localization()
	_test_router_table()
	_test_key_lint()
	_test_no_hardcoded_cjk()
	preload("res://tests/unit/state_tests.gd").new().run(_check)
	preload("res://tests/unit/rules_tests.gd").new().run(_check, Loc)
	preload("res://tests/unit/m6_tests.gd").new().run(_check, Loc)
	preload("res://tests/unit/m7_tests.gd").new().run(_check, Loc)
	preload("res://tests/unit/m8_tests.gd").new().run(_check, Loc)
	preload("res://tests/unit/m9_tests.gd").new().run(_check, Loc)
	preload("res://tests/unit/m10_tests.gd").new().run(_check, Loc)
	preload("res://tests/unit/m11_tests.gd").new().run(_check, Loc)
	preload("res://tests/unit/m12_tests.gd").new().run(_check, Loc)
	preload("res://tests/unit/m13_tests.gd").new().run(_check, Loc)
	preload("res://tests/unit/m15_tests.gd").new().run(_check, Loc)
	preload("res://tests/unit/m16_tests.gd").new().run(_check, Loc)
	preload("res://tests/unit/m17_tests.gd").new().run(_check, Loc)
	preload("res://tests/unit/m18_tests.gd").new().run(_check, Loc)
	preload("res://tests/unit/m19_tests.gd").new().run(_check, Loc)
	preload("res://tests/unit/m20_tests.gd").new().run(_check, Loc)
	preload("res://tests/unit/m20b_tests.gd").new().run(_check, Loc)
	preload("res://tests/unit/m20c_tests.gd").new().run(_check, Loc)
	preload("res://tests/unit/m21_tests.gd").new().run(_check, Loc)
	preload("res://tests/unit/m22_tests.gd").new().run(_check, Loc)
	preload("res://tests/unit/m22c_tests.gd").new().run(_check, Loc)
	preload("res://tests/unit/m22d_tests.gd").new().run(_check, Loc)
	preload("res://tests/unit/m23_tests.gd").new().run(_check, Loc)
	preload("res://tests/unit/m23b_tests.gd").new().run(_check, Loc)
	preload("res://tests/unit/m24a_tests.gd").new().run(_check, Loc)
	preload("res://tests/unit/m24b_tests.gd").new().run(_check, Loc)
	preload("res://tests/unit/m24c_tests.gd").new().run(_check, Loc)
	preload("res://tests/unit/m24d_tests.gd").new().run(_check, Loc)
	preload("res://tests/unit/m25a_tests.gd").new().run(_check, Loc)
	preload("res://tests/unit/m25b_tests.gd").new().run(_check, Loc)
	preload("res://tests/unit/m25c_tests.gd").new().run(_check, Loc)
	preload("res://tests/unit/m25d_tests.gd").new().run(_check, Loc)
	preload("res://tests/unit/m26_tests.gd").new().run(_check, Loc)
	preload("res://tests/unit/m27_tests.gd").new().run(_check, Loc)
	preload("res://tests/unit/m27b_tests.gd").new().run(_check, Loc)
	preload("res://tests/unit/drag_scroll_tests.gd").new().run(_check, Loc)
	for case in [[390, 844, "portrait"], [360, 640, "portrait"], [768, 1024, "portrait"], [844, 390, "landscape"], [1280, 720, "landscape"], [800, 800, "landscape"], [1, 2, "portrait"]]:
		_check(Layout.mode_for(Vector2(case[0], case[1])) == case[2], "layout: %dx%d is %s" % [case[0], case[1], case[2]])
	_check(Layout.PORTRAIT_SIZE.x < Layout.PORTRAIT_SIZE.y and Layout.LANDSCAPE_SIZE.x > Layout.LANDSCAPE_SIZE.y, "layout: design sizes have the right orientation")
	print("UNIT_RESULT checks=%d failures=%d" % [_count, _fails.size()])
	print("UNIT_OK" if _fails.is_empty() else "UNIT_FAIL")
	get_tree().quit(0 if _fails.is_empty() else 1)


func _test_localization() -> void:
	var l := _fresh_loc()
	_check(l.locale == "zh_CN", "default locale is Mandarin")
	_check(l.t("title.name") == "玉谷传奇", "zh lookup")
	l.set_locale("en")
	_check(l.t("title.name") == "Jade Valley Chronicles", "en lookup")
	_check(l.t("spike.fallback_only_zh") != "[spike.fallback_only_zh]", "missing en key falls back to zh")
	_check(l.t("no.such.key") == "[no.such.key]", "missing everywhere shows [key]")
	_check(l.t("recruit.reason.day", {"need": 3}) == "Available from week 3", "placeholder substitution (en)")
	l.set_locale("zh_CN")
	_check(l.t("recruit.reason.day", {"need": 3}) == "第 3 周起可邀请", "placeholder substitution (zh)")
	var got: Array = []
	l.locale_changed.connect(func(c: String) -> void: got.append(c))
	l.set_locale("en")
	l.set_locale("en")  # no change, must not emit twice
	l.set_locale("xx")  # unsupported, ignored
	_check(got == ["en"], "locale_changed emits once, ignores unsupported")
	l.free()


func _test_router_table() -> void:
	var router: Node = load("res://scripts/services/scene_router.gd").new()
	for key in router.SCENES:
		_check(ResourceLoader.exists(router.SCENES[key]), "scene file exists for '%s'" % key)
	router.free()


func _gd_files(dir: String, skip: Array = []) -> Array[String]:
	var out: Array[String] = []
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".gd"):
			out.append(dir.path_join(f))
	for d in DirAccess.get_directories_at(dir):
		if d in skip:
			continue
		out.append_array(_gd_files(dir.path_join(d), skip))
	return out


func _test_key_lint() -> void:
	# Every literal Loc.t("...") key used in scenes/scripts must exist in zh_CN.
	var l := _fresh_loc()
	var re := RegEx.new()
	re.compile("Loc\\.t\\(\"([a-z0-9_.]+)\"[,)]")
	var used := 0
	for path in _gd_files("res://scenes", ["spike"]) + _gd_files("res://scripts"):
		var src := FileAccess.get_file_as_string(path)
		for m in re.search_all(src):
			used += 1
			_check(l.has_key(m.get_string(1), "zh_CN"), "zh key exists: %s (%s)" % [m.get_string(1), path])
	_check(used > 0, "key-lint found Loc.t usages")
	# English may lag, but every English key must also exist in Mandarin (no orphans).
	for k in l.all_keys("en"):
		_check(l.has_key(k, "zh_CN"), "en key has zh counterpart: %s" % k)
	l.free()


func _test_no_hardcoded_cjk() -> void:
	# Player-visible Chinese belongs in locale files, never in scripts. The spike scene is exempt.
	var re := RegEx.new()
	re.compile("[\\x{3400}-\\x{9FFF}\\x{3000}-\\x{303F}\\x{FF00}-\\x{FFEF}]")
	for path in _gd_files("res://scenes", ["spike"]) + _gd_files("res://scripts"):
		_check(re.search(FileAccess.get_file_as_string(path)) == null, "no hard-coded CJK in %s" % path)
