extends RefCounted
## Painted bust portraits: res://art/characters/<id>/<id>_face_<face>.png. Missing files simply return null, and the
## caller keeps its code-drawn placeholder. The hero uses hero_m or hero_f by the chosen gender.

const FACES := ["neutral", "happy", "sad", "angry", "surprised"]
static var _cache: Dictionary = {}


static func texture_for(id: String, face: String = "neutral") -> Texture2D:
	var f: String = face if FACES.has(face) else "neutral"
	var key := "%s/%s" % [id, f]
	if _cache.has(key):
		return _cache[key]
	var path := "res://art/characters/%s/%s_face_%s.png" % [id, id, f]
	var tex: Texture2D = load(path) as Texture2D if ResourceLoader.exists(path) else null
	_cache[key] = tex
	return tex


## Character id of a dialogue speaker key ("npc.su_dai" -> "su_dai", "world.speaker.hero" -> hero_m / hero_f); "" if none.
static func speaker_id(speaker_key: String, hero_gender: String) -> String:
	if speaker_key == "world.speaker.hero":
		return "hero_f" if hero_gender == "f" else "hero_m"
	if speaker_key.begins_with("npc."):
		return speaker_key.trim_prefix("npc.")
	return ""
