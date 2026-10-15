extends RefCounted
## Activity animation clips: a few seconds of the hero's chibi doing the activity. A clip is data (background, duration,
## timeline of pose keys); this samples it. Real sprite clips can later reuse the same ids.

const StageRules = preload("res://scripts/domain/stage_rules.gd")


## The key in force at time t: {pose, face}.
static func key_at(clip: Dictionary, t: float) -> Dictionary:
	var cur: Dictionary = {"pose": "idle", "face": "neutral"}
	for k in clip.get("keys", []):
		if float(k.t) <= t:
			cur = {"pose": str(k.pose), "face": str(k.get("face", "neutral"))}
	return cur


static func problems(clip: Dictionary) -> Array[String]:
	var out: Array[String] = []
	var id := str(clip.get("id", ""))
	var d := float(clip.get("duration", 0.0))
	if d < 1.0 or d > 4.0:
		out.append("clip %s: duration must be 1 to 4 seconds" % id)
	if not StageRules.BACKGROUNDS.has(str(clip.get("bg", ""))):
		out.append("clip %s: unknown background" % id)
	var keys: Array = clip.get("keys", [])
	if keys.is_empty() or float(keys[0].t) != 0.0:
		out.append("clip %s: the first key must be at t=0" % id)
	var last := -1.0
	for k in keys:
		if float(k.t) <= last or float(k.t) >= d:
			out.append("clip %s: keys must increase and stay inside the duration" % id)
		last = float(k.t)
		if not StageRules.POSES.has(str(k.get("pose", ""))):
			out.append("clip %s: unknown pose '%s'" % [id, str(k.get("pose", ""))])
		if not StageRules.FACES.has(str(k.get("face", "neutral"))):
			out.append("clip %s: unknown face" % id)
	return out
