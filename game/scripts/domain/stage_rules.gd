extends RefCounted
## Story-board state: which background and which characters are on stage. Dialogue nodes carry a `stage` list of
## commands; applying them to a plain dictionary keeps the stage saveable and testable without any UI.
## Persistent commands: bg, show, hide, pose, face, move, focus, clear.
## Transient commands (the screen plays them when the node appears, nothing is stored): shake, flash, fade, sfx.

const SLOTS := ["left", "center", "right", "far"]
const POSES := ["idle", "walk", "bow", "laugh", "cry", "angry", "think", "hit", "victory", "kneel", "train", "sword", "fish", "mine", "music", "chess"]
const FACES := ["neutral", "happy", "sad", "angry", "surprised"]
const BACKGROUNDS := ["valley_dawn", "valley_day", "village_dusk", "riverside_day", "terraces_green", "shrine_night", "ferry_dusk", "night_camp", "default"]
const PERSISTENT := ["bg", "show", "hide", "pose", "face", "move", "focus", "clear"]
const TRANSIENT := ["shake", "flash", "fade", "sfx"]


static func blank() -> Dictionary:
	return {"bg": "default", "actors": {}, "focus": ""}


## Cleans a stored stage (from a save) so the screen can always draw it.
static func sanitize(d: Variant) -> Dictionary:
	var out := blank()
	if not (d is Dictionary):
		return out
	if BACKGROUNDS.has(str(d.get("bg", ""))):
		out.bg = str(d.bg)
	var actors: Variant = d.get("actors", {})
	if actors is Dictionary:
		for slot in SLOTS:
			var a: Variant = actors.get(slot)
			if a is Dictionary and str(a.get("who", "")) != "":
				out.actors[slot] = {"who": str(a.who), "pose": str(a.get("pose", "idle")) if POSES.has(str(a.get("pose", "idle"))) else "idle",
						"face": str(a.get("face", "neutral")) if FACES.has(str(a.get("face", "neutral"))) else "neutral"}
	out.focus = str(d.get("focus", ""))
	return out


static func apply(stage: Dictionary, commands: Array) -> void:
	for c in commands:
		var cmd := str(c.get("c", ""))
		var slot := str(c.get("slot", ""))
		match cmd:
			"bg":
				stage.bg = str(c.get("id", "default"))
			"show":
				stage.actors[slot] = {"who": str(c.get("who", "")), "pose": str(c.get("pose", "idle")), "face": str(c.get("face", "neutral"))}
			"hide":
				if slot != "":
					stage.actors.erase(slot)
				else:
					for s in stage.actors.keys():
						if str(stage.actors[s].who) == str(c.get("who", "")):
							stage.actors.erase(s)
			"pose", "face":
				if stage.actors.has(slot):
					stage.actors[slot][cmd] = str(c.get(cmd, "idle" if cmd == "pose" else "neutral"))
			"move":
				var to := str(c.get("to", ""))
				if stage.actors.has(slot) and to != "" and to != slot:
					stage.actors[to] = stage.actors[slot]
					stage.actors.erase(slot)
			"focus":
				stage.focus = str(c.get("who", ""))
			"clear":
				stage.actors = {}
				stage.focus = ""


static func transient(commands: Array) -> Array:
	return commands.filter(func(c: Dictionary) -> bool: return TRANSIENT.has(str(c.get("c", ""))))


## Problems with one command, for the content validator. `known_who` is a Callable(id) -> bool.
static func problems(cmd: Dictionary, known_who: Callable) -> Array[String]:
	var out: Array[String] = []
	var c := str(cmd.get("c", ""))
	if not PERSISTENT.has(c) and not TRANSIENT.has(c):
		out.append("unknown stage command '%s'" % c)
		return out
	if ["show", "pose", "face", "move"].has(c) or (c == "hide" and cmd.has("slot")):
		if not SLOTS.has(str(cmd.get("slot", ""))):
			out.append("%s: bad slot '%s'" % [c, str(cmd.get("slot", ""))])
	if c == "move" and not SLOTS.has(str(cmd.get("to", ""))):
		out.append("move: bad target slot")
	if c == "show":
		if not known_who.call(str(cmd.get("who", ""))):
			out.append("show: unknown character '%s'" % str(cmd.get("who", "")))
		if cmd.has("pose") and not POSES.has(str(cmd.pose)):
			out.append("show: unknown pose '%s'" % str(cmd.pose))
		if cmd.has("face") and not FACES.has(str(cmd.face)):
			out.append("show: unknown face '%s'" % str(cmd.face))
	if c == "pose" and not POSES.has(str(cmd.get("pose", ""))):
		out.append("pose: unknown pose")
	if c == "face" and not FACES.has(str(cmd.get("face", ""))):
		out.append("face: unknown face")
	if c == "bg" and not BACKGROUNDS.has(str(cmd.get("id", ""))):
		out.append("bg: unknown background '%s'" % str(cmd.get("id", "")))
	if c == "hide" and not cmd.has("slot") and not cmd.has("who"):
		out.append("hide: needs slot or who")
	return out
