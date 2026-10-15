extends RefCounted
## Localization lint (M13): coverage, placeholders, unused keys, hard-coded text, glyph coverage.
## Used by the unit tests (m13_tests) and by tests/lint_keys.gd, which writes the report.

const INTENTIONAL_ZH_ONLY := ["spike.fallback_only_zh"]  # proves the English -> Mandarin fallback
const KEY_RE := "^[a-z0-9_]+(\\.[a-z0-9_]+)+$"


static func files(dir: String, ext: String, skip: Array = []) -> Array:
	var out: Array = []
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(ext):
			out.append(dir.path_join(f))
	for d in DirAccess.get_directories_at(dir):
		if not skip.has(d):
			out.append_array(files(dir.path_join(d), ext, skip))
	return out


static func table(code: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://content/localization/%s.json" % code))
	return parsed if parsed is Dictionary else {}


static func placeholders(text: String) -> Array:
	var re := RegEx.new()
	re.compile("\\{([a-z_0-9]+)\\}")
	var out: Array = []
	for m in re.search_all(text):
		if not out.has(m.get_string(1)):
			out.append(m.get_string(1))
	out.sort()
	return out


## Everything the checks need in one dictionary.
static func run(loc: Node) -> Dictionary:
	var zh := table("zh_CN")
	var en := table("en")
	var r := {"zh_count": zh.size(), "en_count": en.size(), "missing_zh": [], "missing_en": [], "placeholder_mismatch": [],
		"unused": [], "hardcoded": [], "missing_glyphs": {}, "bad_content_keys": []}
	for k in en:
		if not zh.has(k):
			r.missing_zh.append(k)
	for k in zh:
		if not en.has(k) and not INTENTIONAL_ZH_ONLY.has(k):
			r.missing_en.append(k)
		if en.has(k) and placeholders(str(zh[k])) != placeholders(str(en[k])):
			r.placeholder_mismatch.append(k)
	# Which keys does anything refer to? A literal key counts; so does a literal prefix such as "path." used to build keys.
	var corpus := ""
	var json_values: Array = []
	for p in files("res://scenes", ".gd", ["spike"]) + files("res://scripts", ".gd"):
		corpus += FileAccess.get_file_as_string(p)
	var spike := ""
	for p in files("res://scenes/spike", ".gd"):
		spike += FileAccess.get_file_as_string(p)
	var key_re := RegEx.new()
	key_re.compile(KEY_RE)
	for p in files("res://content", ".json", ["localization"]):
		var text := FileAccess.get_file_as_string(p)
		corpus += text
		_collect_keys(JSON.parse_string(text), json_values)
	var prefixes := {}
	var pre_re := RegEx.new()
	pre_re.compile("\"([a-z0-9_]+(?:\\.[a-z0-9_]+)*\\.)\"")
	for m in pre_re.search_all(corpus):
		prefixes[m.get_string(1)] = true
	for k in zh:
		if corpus.contains("\"%s\"" % k) or spike.contains("\"%s\"" % k):
			continue
		var covered := false
		for pfx in prefixes:
			if str(k).begins_with(pfx):
				covered = true
				break
		if not covered:
			r.unused.append(k)
	# Keys named in content must exist.
	for v in json_values:
		if not zh.has(v) and key_re.search(v) != null:
			r.bad_content_keys.append(v)
	# Hard-coded text: a literal with letters assigned to a text property (format characters do not count).
	var assign := RegEx.new()
	assign.compile("\\.(text|tooltip_text|placeholder_text)\\s*=\\s*\"((?:[^\"\\\\]|\\\\.)*)\"")
	var letters := RegEx.new()
	letters.compile("[A-Za-z\\x{3400}-\\x{9FFF}]")
	var fmt := RegEx.new()
	fmt.compile("%[-+0-9.]*[sdfx]|\\\\n|\\\\t")
	for p in files("res://scenes", ".gd", ["spike"]) + files("res://scripts", ".gd"):
		var n := 0
		for line in FileAccess.get_file_as_string(p).split("\n"):
			n += 1
			var m := assign.search(line)
			if m != null and letters.search(fmt.sub(m.get_string(2), "", true)) != null:
				r.hardcoded.append("%s:%d" % [p, n])
	# Glyphs: every character of both tables must be drawable with the bundled font.
	for code in ["zh_CN", "en"]:
		var all := ""
		var tbl := table(code)
		for k in tbl:
			if not str(k).begins_with("spike."):  # the engine spike deliberately shows out-of-subset glyphs
				all += str(tbl[k])
		var miss: Array = loc.missing_glyphs(all)
		if not miss.is_empty():
			r.missing_glyphs[code] = miss
	return r


static func _collect_keys(node: Variant, out: Array) -> void:
	if node is Dictionary:
		for k in node:
			if str(k).ends_with("_key") and node[k] is String:
				out.append(node[k])
			else:
				_collect_keys(node[k], out)
	elif node is Array:
		for e in node:
			_collect_keys(e, out)
