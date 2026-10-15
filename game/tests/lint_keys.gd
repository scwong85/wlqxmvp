extends SceneTree
## godot --headless --path game -s res://tests/lint_keys.gd -- /abs/path/report.md
const KeyLint = preload("res://tests/key_lint.gd")


func _initialize() -> void:
	var loc: Node = root.get_node("Loc")
	var r: Dictionary = KeyLint.run(loc)
	var lines: Array[String] = ["# Localization lint report", "",
		"| Check | Result |", "|---|---|",
		"| Mandarin keys | %d |" % r.zh_count,
		"| English keys | %d (%d%% of Mandarin; the rest fall back to Mandarin) |" % [r.en_count, int(100.0 * r.en_count / maxi(1, r.zh_count))],
		"| English keys missing in Mandarin | %d |" % r.missing_zh.size(),
		"| Mandarin keys without English | %d %s |" % [r.missing_en.size(), str(r.missing_en)],
		"| Placeholder mismatches | %d %s |" % [r.placeholder_mismatch.size(), str(r.placeholder_mismatch)],
		"| Possibly unused keys | %d %s |" % [r.unused.size(), str(r.unused)],
		"| Content keys that do not exist | %d %s |" % [r.bad_content_keys.size(), str(r.bad_content_keys)],
		"| Hard-coded text assignments | %d %s |" % [r.hardcoded.size(), str(r.hardcoded)],
		"| Characters missing from the bundled font | %s |" % str(r.missing_glyphs), ""]
	var out := "\n".join(lines)
	print(out)
	for a in OS.get_cmdline_user_args():
		var f := FileAccess.open(a, FileAccess.WRITE)
		if f != null:
			f.store_string(out)
			f.close()
	quit(0)
