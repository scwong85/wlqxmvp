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
const STORY_SPEAKERS := {"story.speaker.elder": "elder", "story.speaker.villager": "villager", "story.speaker.leader": "leader",
		"world.speaker.villager": "villager", "world.speaker.wanderer": "wanderer"}


static func speaker_id(speaker_key: String, hero_gender: String) -> String:
	if speaker_key == "world.speaker.hero":
		return hero_id(hero_gender)
	if speaker_key.begins_with("npc."):
		return speaker_key.trim_prefix("npc.")
	return str(STORY_SPEAKERS.get(speaker_key, ""))


static func hero_id(gender: String) -> String:
	return "hero_f" if gender == "f" else "hero_m"


## Full-body painted figure (transparent PNG, art/figures/<id>.png). "hero" maps to hero_m / hero_f. Null = use the code skin.
static var _fig_cache: Dictionary = {}


static func figure_for(who: String, gender: String = "m") -> Texture2D:
	var id := hero_id(gender) if who == "hero" else who
	if _fig_cache.has(id):
		return _fig_cache[id]
	var path := "res://art/figures/%s.png" % id
	var tex: Texture2D = load(path) as Texture2D if ResourceLoader.exists(path) else null
	_fig_cache[id] = tex
	return tex


## Square crop of a portrait for round thumbnails, in pixels: Rect2(x, y, side, side). The default is the top square (the
## widest square that fits). Very narrow, tall portraits need a larger square so the whole face shows; the part that
## falls outside the picture repeats the edge colour.
const THUMB := {"shen_qinghe": {"side_w": 1.265, "y0_h": 0.0}, "xiao_hanchuan": {"side_w": 1.657, "y0_h": 0.093}}


static func thumb_rect(id: String, tex: Texture2D) -> Rect2:
	var sz := tex.get_size()
	var side := minf(sz.x, sz.y)
	var y0 := 0.0
	if THUMB.has(id):
		side = sz.x * float(THUMB[id].side_w)
		y0 = sz.y * float(THUMB[id].y0_h)
	return Rect2((sz.x - side) * 0.5, y0, side, side)
